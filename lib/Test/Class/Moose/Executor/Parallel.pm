package Test::Class::Moose::Executor::Parallel;

# ABSTRACT: Execute tests in parallel (parallelized by instance)

use 5.10.0;

our $VERSION = '0.70';

use Moose 2.0000;
use Carp;
use namespace::autoclean;
with 'Test::Class::Moose::Role::Executor';

# Needs to come before we load other test tools
use Test2::IPC;

use List::SomeUtils qw( none part );
use Parallel::ForkManager;
use Scalar::Util qw(reftype);
use Test2::API qw( context_do test2_stack );
use Test2::Tools::AsyncSubtest qw( subtest_start subtest_run subtest_finish );
use Test::Class::Moose::AttributeRegistry;
use Test::Class::Moose::Report::Class;
use Try::Tiny;

has 'jobs' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has '_fork_manager' => (
    is       => 'ro',
    isa      => 'Parallel::ForkManager',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_fork_manager',
);

around _run_test_classes => sub {
    my $orig         = shift;
    my $self         = shift;
    my @test_classes = @_;

    my ( $seq, $par )
      = part { $self->_test_class_is_parallelizable($_) } @test_classes;

    $self->_run_test_classes_in_parallel( @{$par} );

    test2_stack()->top->cull;

    $self->$orig( @{$seq} );

    return;
};

sub _test_class_is_parallelizable {
    my ( $self, $test_class ) = @_;

    return none {
        Test::Class::Moose::AttributeRegistry->method_has_tag(
            $test_class,
            $_,
            'noparallel'
        );
    }
    $self->_test_methods_for($test_class);
}

sub _run_test_classes_in_parallel {
    my $self         = shift;
    my @test_classes = @_;

    my @subtests;
    foreach my $test_class (@test_classes) {
        push @subtests, $self->_run_test_class_in_parallel($test_class);
    }

    $self->_fork_manager->wait_all_children;

    subtest_finish($_) for @subtests;

    return;
}

sub _run_test_class_in_parallel {
    my $self       = shift;
    my $test_class = shift;

    my $class_report
      = Test::Class::Moose::Report::Class->new( name => $test_class );
    $self->test_report->add_test_class($class_report);

    my @test_instances
      = $self->_make_test_instances( $test_class, $class_report )
      or return;

    my @subtests;

    my $class_subtest = subtest_start($test_class);
    subtest_run(
        $class_subtest,
        sub {
            push @subtests,
              $self->_run_test_instances_in_parallel(
                $class_report,
                @test_instances,
              );
        }
    );
    push @subtests, $class_subtest;

    return @subtests;
}

sub _run_test_instances_in_parallel {
    my $self           = shift;
    my $class_report   = shift;
    my @test_instances = @_;

    my @subtests;
    for my $test_instance (
        sort { $a->test_instance_name cmp $b->test_instance_name }
        @test_instances )
    {
        return $self->_run_test_instance_in_parallel(
            $class_report,
            $test_instance,
            @test_instances > 1,
        );
    }
}

sub _run_test_instance_in_parallel {
    my $self          = shift;
    my $class_report  = shift;
    my $test_instance = shift;
    my $in_subtest    = shift;

    unless ($in_subtest) {
        return if $self->_fork_manager->start;

        my $instance_report = $self->_run_test_instance(
            $class_report,
            $test_instance,
        );

        $self->_fork_manager->finish(
            0,
            [ $test_instance->test_class, $instance_report ]
        );
    }

    my $instance_subtest
      = subtest_start( $test_instance->test_instance_name );
    return $instance_subtest if $self->_fork_manager->start;

    subtest_run(
        $instance_subtest,
        sub {
            my $instance_report = $self->_run_test_instance(
                $class_report,
                $test_instance,
            );

            $self->_fork_manager->finish(
                0,
                [ $test_instance->test_class, $instance_report ]
            );
        }
    );
}

sub _build_fork_manager {
    my $self = shift;

    my $pfm = Parallel::ForkManager->new( $self->jobs );
    $pfm->run_on_finish(
        sub {
            my ( $pid, $report_info ) = @_[ 0, 5 ];

          # problems occuring during storage or retrieval will throw a warning
            croak("Child process $pid failed!")
              unless $report_info
              && reftype($report_info) eq 'ARRAY'
              && @{$report_info} == 2;

            $self->test_report->class_named( $report_info->[0] )
              ->add_test_instance( $report_info->[1] );
        }
    );

    return $pfm;
}

1;

=for Pod::Coverage Tags Tests runtests
