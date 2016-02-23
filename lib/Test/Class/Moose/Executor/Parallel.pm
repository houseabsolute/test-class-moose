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

use List::SomeUtils qw(none);
use Parallel::ForkManager;
use Scalar::Util qw(reftype);
use Test2::API qw( context run_subtest test2_stack );
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

sub runtests {
    my $self = shift;

    my $report = $self->test_report;
    $report->_start_benchmark;
    my @test_classes = $self->test_classes;

    my $ctx = context();
    try {
        $ctx->plan( scalar @test_classes );

        $self->_run_test_classes( $ctx, @test_classes );

        $ctx->diag(<<"END") if $self->test_configuration->statistics;
Test classes:    @{[ $report->num_test_classes ]}
Test instances:  @{[ $report->num_test_instances ]}
Test methods:    @{[ $report->num_test_methods ]}
Total tests run: @{[ $report->num_tests_run ]}
END

        $ctx->done_testing;
    }
    catch {
        die $_;
    }
    finally {
        $ctx->release;
    };

    $report->_end_benchmark;
    return $self;
}

sub _run_test_classes {
    my $self         = shift;
    my $ctx          = shift;
    my @test_classes = @_;

    my @sequential = $self->_run_parallel_jobs(@test_classes);

    test2_stack()->top->cull;

    for my $test_class (@sequential) {
        $ctx->note("\nRunning tests for $test_class\n\n");
        my $subtest = subtest_start($test_class);
        subtest_run(
            $subtest,
            sub {
                use Test::Class::Moose::Executor::Sequential;
                $self
                  ->Test::Class::Moose::Executor::Sequential::_tcm_run_test_class
                  ($test_class);
            },
        );
        subtest_finish($subtest);
    }

    return $ctx;
}

sub _run_parallel_jobs {
    my ( $self, $sequential ) = @_;

    my @subtests;
    my @sequential;
    foreach my $test_class ( $self->test_classes ) {
        if ( $self->_test_class_is_parallelizable($test_class) ) {
            push @subtests, $self->_tcm_run_test_class($test_class);
        }
        else {
            push @sequential, $test_class;
        }
    }

    $self->_fork_manager->wait_all_children;

    subtest_finish($_) for @subtests;

    return @sequential;
}

sub _tcm_run_test_class {
    my $self       = shift;
    my $test_class = shift;

    my $class_report
      = Test::Class::Moose::Report::Class->new( name => $test_class );
    $self->test_report->add_test_class($class_report);

    my @test_instances = $test_class->_tcm_make_test_class_instances(
        $self->test_configuration->args,
        test_report => $self->test_report,
    );

    my @subtests;
    if ( @test_instances > 1 ) {
        my $class_subtest = subtest_start($test_class);
        subtest_run(
            $class_subtest => sub {
                push @subtests,
                  $self->_run_test_instances_in_parallel(
                    $class_report,
                    @test_instances
                  );
            }
        );
        push @subtests, $class_subtest;
    }
    else {
        push @subtests,
          $self->_run_test_instances_in_parallel(
            $class_report,
            @test_instances
          );
    }

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
        my $instance_subtest
          = subtest_start( $test_instance->test_instance_name );
        return $instance_subtest if $self->_fork_manager->start;

        subtest_run(
            $instance_subtest,
            sub {
                my $instance_report = $self->_tcm_run_test_instance(
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
}

sub _test_class_is_parallelizable {
    my ( $self, $test_class ) = @_;

    return none {
        Test::Class::Moose::AttributeRegistry->method_has_tag(
            $test_class,
            $_,
            'noparallel'
        );
    }
    $self->_tcm_test_methods_for($test_class);
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
