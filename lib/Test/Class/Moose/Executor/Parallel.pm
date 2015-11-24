package Test::Class::Moose::Executor::Parallel;

# ABSTRACT: Execute tests in parallel (parallelized by instance)

use 5.10.0;

our $VERSION = '0.64';

use Moose 2.0000;
use Carp;
use namespace::autoclean;
with 'Test::Class::Moose::Role::Executor';

use List::MoreUtils qw(none);
use Parallel::ForkManager;
use TAP::Stream 0.44;
use Test::Builder;
use Test::Class::Moose::AttributeRegistry;
use Test::Class::Moose::Report::Class;

use List::MoreUtils qw(uniq);

has 'jobs' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'color_output' => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
);

has '_color' => (
    is         => 'ro',
    isa        => 'TAP::Formatter::Color',
    lazy_build => 1,
);

sub runtests {
    my $self = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 4;
    my $jobs = $self->jobs;

    # We need to fetch this output handle before forking off jobs. Otherwise,
    # we lose our test builder output if we have a sequential job after the
    # parallel jobs. This happens because we explicitly set the builder's
    # output to a scalar ref in our $run_instance sub above.
    my $test_builder_output = Test::Builder->new->output;
    my $stream              = TAP::Stream->new;

    my $fork = $self->_make_fork_manager($stream);

    my @sequential;
    $self->_run_parallel_jobs( $fork, \@sequential );

    for my $pair (@sequential) {
        my $output = $self->_run_instance( @{$pair} );
        $stream->add_to_stream(
            TAP::Stream::Text->new(
                text => $output,
                name =>
                  "Sequential tests for $pair->[0] run after parallel tests",
            )
        );
    }

    # this prevents overwriting the line of dots output from
    # $RUN_TEST_CONTROL_METHOD
    print STDERR "\n";

    # this is where we print the TAP results
    print $test_builder_output $stream->to_string;

    return $self;
}

sub _make_fork_manager {
    my ( $self, $stream ) = @_;

    my $fork = Parallel::ForkManager->new( $self->jobs );
    $fork->run_on_finish(
        sub {
            my ($pid, $exit_code, $ident, $exit_signal, $core_dump,
                $result
            ) = @_;

            if ( defined($result) ) {
                my ( $job_num, $tap ) = @$result;
                $stream->add_to_stream(
                    TAP::Stream::Text->new(
                        text => $tap, name => "Job #$job_num (pid: $pid)"
                    )
                );
            }
            else
            { # problems occuring during storage or retrieval will throw a warning
                carp("No TAP received from child process $pid!");
            }
        }
    );

    return $fork;
}

sub _run_parallel_jobs {
    my ( $self, $fork, $sequential ) = @_;

    my @test_classes = $self->test_classes;

    my $job_num = 0;
    foreach my $test_class ( $self->test_classes ) {
        my $class_report
          = Test::Class::Moose::Report::Class->new( name => $test_class );
        $self->test_report->add_test_class($class_report);

        my %test_instances = $test_class->_tcm_make_test_class_instances(
            $self->test_configuration->args,
            test_report => $self->test_report,
        );

        foreach my $test_instance_name ( sort keys %test_instances ) {
            my $test_instance = $test_instances{$test_instance_name};
            if ( $self->_test_instance_is_parallelizable($test_instance) ) {
                $job_num++;
                my $pid = $fork->start and next;
                my $output = $self->_run_instance(
                    $test_instance_name,
                    $test_instance
                );
                $fork->finish( 0, [ $job_num, $output ] );
            }
            else {
                push @{$sequential}, [ $test_instance_name, $test_instance ];
            }
        }
    }
    $fork->wait_all_children;

    return;
}

sub _test_instance_is_parallelizable {
    my ( $self, $test_instance ) = @_;

    my $test_class = $test_instance->test_class;
    return none {
        Test::Class::Moose::AttributeRegistry->method_has_tag(
            $test_class,
            $_,
            'noparallel'
        );
    }
    $self->_tcm_test_methods_for_instance($test_instance);
}

sub _run_instance {
    my ( $self, $test_instance_name, $test_instance ) = @_;

    my $builder = Test::Builder->new;

    my $output;
    $builder->output( \$output );
    $builder->failure_output( \$output );
    $builder->todo_output( \$output );

    $self->_tcm_run_test_instance( $test_instance_name, $test_instance );

    return $output;
}

after '_tcm_run_test_method' => sub {
    my $self    = shift;
    my $config  = $self->test_configuration;
    my $builder = $config->builder;

    # we're running under parallel testing, so rather than having
    # the code look like it's stalled, we'll output a dot for
    # every test method.
    my ( $color, $text )
      = ( $builder->details )[-1]{ok}
      ? ( 'green', '.' )
      : ( 'red', 'X' );

    # The set_color() method from Test::Formatter::Color is just ugly.
    if ( $self->color_output ) {
        $self->_color->set_color(
            sub { print STDERR shift, $text },
            $color,
        );
        $self->_color->set_color( sub { print STDERR shift }, 'reset' );
    }
    else {
        print STDERR $text;
    }
};

sub _build__color {
    return TAP::Formatter::Color->new;
}

1;

=for Pod::Coverage Tags Tests runtests
