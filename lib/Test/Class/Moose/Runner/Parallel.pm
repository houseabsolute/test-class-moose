package Test::Class::Moose::Runner::Parallel;

# ABSTRACT: Run tests in parallel (parallelized by instance)

use 5.10.0;
use Moose 2.0000;
use Carp;
use namespace::autoclean;
with 'Test::Class::Moose::Role::Runner';

use List::MoreUtils qw(none);
use Parallel::ForkManager;
use TAP::Stream 0.44;
use Test::Builder;
use Test::Class::Moose::AttributeRegistry;

use List::MoreUtils qw(uniq);

has 'jobs' => (
    is      => 'ro',
    isa     => 'Int',
    default => 1,
);

has 'color_output' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has '_color' => (
    is         => 'rw',
    isa        => 'TAP::Formatter::Color',
    lazy_build => 1,
);

my $run_instance = sub {
    my ( $self, $test_instance_name, $test_instance ) = @_;

    my $builder = Test::Builder->new;

    my $output;
    $builder->output( \$output );
    $builder->failure_output( \$output );
    $builder->todo_output( \$output );

    $self->_tcm_run_test_instance( $test_instance_name, $test_instance );

    return $output;
};

sub runtests {
    my $self = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 4;
    my $jobs = $self->jobs;

    if ( $jobs < 2 ) {
        require Test::Class::Moose::Runner::Sequential;
        Test::Class::Moose::Runner::Sequential->new(
            test_configuration => $self->test_configuration )->runtests();
        return;
    }

    # We need to fetch this output handle before forking off jobs. Otherwise,
    # we lose our test builder output if we have a sequential job after the
    # parallel jobs. This happens because we explicitly set the builder's
    # output to a scalar ref in our $run_instance sub above.
    my $test_builder_output = Test::Builder->new->output;
    my $stream              = TAP::Stream->new;

    my $fork = $self->_make_fork_manager($stream);

    my @sequential;
    $self->_run_parallel_jobs($fork, \@sequential);

    for my $pair (@sequential) {
        my $output = $self->$run_instance( @{$pair} );
        $stream->add_to_stream( TAP::Stream::Text->new(
            text => $output,
            name => "Sequential tests for $pair->[0] run after parallel tests",
        ) );
    }

    # this prevents overwriting the line of dots output from
    # $RUN_TEST_CONTROL_METHOD
    print STDERR "\n";

    # this is where we print the TAP results
    print $test_builder_output $stream->to_string;
}

sub _make_fork_manager {
    my ( $self, $stream ) = @_;

    my $fork = Parallel::ForkManager->new($self->jobs);
    $fork->run_on_finish(
        sub {
            my ($pid, $exit_code, $ident, $exit_signal, $core_dump,
                $result
            ) = @_;

            if ( defined($result) ) {
                my ( $job_num, $tap ) = @$result;
                $stream->add_to_stream(
                    TAP::Stream::Text->new( text => $tap, name => "Job #$job_num (pid: $pid)" ) );
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
        my %test_instances
            = $test_class->_tcm_make_test_class_instances(
            $self->test_configuration->args );

        foreach my $test_instance_name (sort keys %test_instances) {
            my $test_instance = $test_instances{$test_instance_name};
            if ( $self->_test_instance_is_parallelizable($test_instance) ) {
                $job_num++;
                my $pid = $fork->start and next;
                my $output = $self->$run_instance(
                    $test_instance_name,
                    $test_instance
                );
                $fork->finish( 0, [ $job_num, $output ] );
            }
            else {
                push @{$sequential}, [$test_instance_name, $test_instance];
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

__END__

=head1 SYNOPSIS

    package TestsFor::Some::Class;
    use Test::Class::Moose;
    with 'Test::Class::Moose::Role::Parallel';

    sub schedule {
       ...
       return \@schedule;
    }

And in your test driver:

    my $test_suite = MyParallelTests->new(
        show_timing => 0,
        jobs        => $jobs,
        statistics  => 1,
    );
    $test_suite->runtests;

=head1 DESCRIPTION

This is a very experimental role to add parallel testing to
C<Test::Class::Moose>. The interface is subject to change and it probably
won't magically make your tests I<successfully> run in parallel unless you're
really lucky. If you've tried to parallelize your tests before, you understand
why: database tests don't use transactions, or some test munges global state,
and so on.

B<Important>: At the present time, attempting to run jobs in parallel means
that the C<Test::Class::Moose::test_report()> method will not return anything
useful after the test suite is run, so don't try to call it afterwards. You
may still call it inside of a test class or test method as normal.

To use this role, simply include:

    with qw(
        Test::Class::Moose::Role::Parallel
    );

And in your driver script, the constructor takes a new argument, C<jobs>.

    my $test_suite = MyParallelTests->new(
        jobs => $jobs,
    );
    $test_suite->runtests;

If the C<jobs> is set to 1, then it's as if you've run things like normal.
However, if C<jobs> is greater than 1, we'll fork off numerous jobs and run
the tests in parallel according to the schedule. If you have L<Sub::Attribute>
installed, then all test methods tagged with C<noparallel> will run
sequentially after the parallel tests:

    sub test_destructive_code : Tags(noparallel) {
        my $test = shift;
        # run some tests here here that can't be run in parallel
    }

If you need to write your own schedule, you can use the following naive
schedule as a template:

    sub schedule {
        my $self   = shift;
        my $config = $self->test_configuration;
        my $jobs   = $config->jobs;
        my @schedule;

        my $current_job = 0;
        foreach my $test_class ( $self->test_classes ) {
            my $test_instance = $test_class->new( $config->args );
            foreach my $method ( $test_instance->test_methods ) {
                $schedule[$current_job] ||= {};

                # assign a method for a class to a given job
                $schedule[$current_job]{$test_class}{$method} = 1;
                $current_job++;
                $current_job = 0 if $current_job >= $jobs;
            }
        }
        unshift @schedule => undef; # we have no sequential jobs
        return @schedule;
    }

Each job in the schedule is a hashref. The keys are the names of classes for
that job and the values are a hashref. The keys of the latter hashref are
methods for that class for that job and their values B<must> be true. For
example, a single job with two classes and six methods (3 per class) may look
like this:

    {
        'TestsFor::Person' => {
            test_name => 1,
            test_age  => 1,
            test_ssn  => 1,
        },
        'TestsFor::Person::Employee' => {
            test_employee_number => 1,
            test_manager         => 1,
            test_name            => 1,
        },
    }

Note that a class may be spread over multiple jobs. That's perfectly fine.
This is an example of a complete schedule from the test suite, spread across
two jobs:

    @schedule = (
      undef,                              # no sequential tests
      {                                   # first job
        'TestsFor::Alpha' => {
          test_alpha_first => 1
        },
        'TestsFor::Alpha::Subclass' => {
          test_alpha_first => 1,
          test_second      => 1
        },
        'TestsFor::Beta' => {
          test_second => 1
        }
      },
      {                                   # second job
        'TestsFor::Alpha' => {
          test_second => 1
        },
        'TestsFor::Alpha::Subclass' => {
          test_another => 1
        },
        'TestsFor::Beta' => {
          test_beta_first => 1
        }
      }
    );

If the first "job" listed in the schedule it not undef, it will be considered
to be tests that must be run sequentially after all other tests have finished
running in parallel. This is for tests methods which, for whatever reason,
cannot run in parallel.

In other words, the C<@schedule> returned looks like this if you request four
jobs:

    my @schedule = (
        \%jobs_to_run_sequentially_after_parallel_tests,
        \%classes_and_their_methods_for_job_1,
        \%classes_and_their_methods_for_job_2,
        \%classes_and_their_methods_for_job_3,
        \%classes_and_their_methods_for_job_4,
    );

=head1 CREATING YOUR OWN SCHEDULE

You may wish to create your own C<schedule()> method, using the above above as
a guideline. It naively walks your classes and their methods and distributes
them evenly across your jobs. That probably won't work for you. For example,
it's possible that you'll wind up accidentally grouping long-running test
methods in a single job when you want them in separate jobs. Use the C<<
$test_suite->test_report >> I<without> running the tests in parallel to
determine which classes and methods take longer to run, save this information
and then use that to build an effective schedule.

Another reason the naive approach won't work is because you probably have
tests that don't run in parallel (for example, they munge global state or
they drop and recreate a database). You'll need to use your C<schedule()> to
add them to the job listed in C<$schedule[0]>. However, if you have
L<Sub::Attribute> installed, you can use the C<noparallel> tag to mark tests
that must not be run in parallel:

    sub test_database_migrations : Tags(noparallel) {
        my $test = shift;
        # potentially destructive tests here
    }

Of course, if you provide your own schedule, you'll need to account for the
C<noparallel> tag yourself, or use something else.

Or it could be that some tests run in parallel with some tests, but not
others. Again, your schedule needs to be written to take that into account.

To manage this information better, if you can use tags, you'll find that
C<Test::Class::Moose::AttributeRegistry> can help:

    use aliased 'Test::Class::Moose::AttributeRegistry';

    if ( AttributeRegistry->method_has_tag( $class, $method, $tag ) ) {

        # put the method in the appropriate job
    }

=head1 INTERNALS

This is all subject to wild change, but surprisingly, we didn't have to do any
monkey-patching of code. It works like this:

We use C<Parallel::ForkManager> to create our jobs.

For each job, we grab the schedule for that job number and the C<test_classes>
and C<test_methods> methods only return classes and methods in the current job
schedule. Then we run only those tests, but capture the output like this:


    my $builder = Test::Builder->new;

    my $output;
    $builder->output( \$output );
    $builder->failure_output( \$output );
    $builder->todo_output( \$output );

    $self->runtests;

    # $output contains the TAP

Afterwards, if there are any sequential tests, we run them using the above
procedure.

All output is assembled using the experimental L<TAP::Stream> module bundled
with this one. If it works, we may break it into a separate distribution
later. That module allows you to combine multiple TAP streams into a single
stream using subtests.

Then we simply print the resulting combined TAP to the current
L<Test::Builder> output handle (defaults to STDOUT) and C<prove> can read the
output as usual.

Note that because we're merging the regular output, failure output, and TODO
output into a single stream, there could be side effects if your failure
output or TODO output resembles TAP (and doesn't have a leading '#' mark to
indicate that it should be ignored).

=head1 PERFORMANCE

For our C<t/parallellib> test suite, we go from 11 seconds on a regular test
run down to 2 seconds when running with 8 jobs.
