package Test::Class::Moose::Report;

# ABSTRACT: Test information for Test::Class::Moose

use 5.010000;

our $VERSION = '0.96';

use Carp;
use Moose;
use namespace::autoclean;
with 'Test::Class::Moose::Role::HasTimeReport';

use List::Util qw( first sum0 );

has test_classes => (
    is      => 'ro',
    traits  => ['Array'],
    isa     => 'ArrayRef[Test::Class::Moose::Report::Class]',
    default => sub { [] },
    handles => {
        _all_test_classes => 'elements',
        add_test_class    => 'push',
        num_test_classes  => 'count',
    },
);

sub num_test_instances {
    my $self = shift;
    return sum0 map { $_->num_test_instances } $self->all_test_classes;
}

sub num_test_methods {
    my $self = shift;
    return scalar grep { !$_->is_skipped }
      map              { $_->all_test_methods }
      map              { $_->all_test_instances } $self->all_test_classes;
}

sub num_tests_run {
    my $self = shift;
    return sum0 map { $_->num_tests_run }
      grep          { !$_->is_skipped }
      map           { $_->all_test_methods }
      map           { $_->all_test_instances } $self->all_test_classes;
}

sub all_test_classes {
    my $self = shift;
    return $self->_all_test_classes;
}

sub current_class {
    my $self = shift;
    return $self->test_classes->[-1];
}

sub current_instance {
    my $self = shift;
    my $current_class = $self->current_class or return;
    return $current_class->current_instance;
}

sub current_method {
    my $self = shift;
    my $current_instance = $self->current_instance or return;
    return $current_instance->current_method;
}

sub plan {
    my ( $self, $plan ) = @_;
    my $current_method = $self->current_method
      or croak("You tried to plan but we don't have a test method yet!");
    $current_method->plan($plan);
}

sub timing_data {
    my $self = shift;

    my %t = ( time => $self->time->as_hashref );

    for my $class ( $self->all_test_classes ) {
        my $class_inner = $t{class}{ $class->name }
          = { time => $class->time->as_hashref };

        for my $instance ( $class->all_test_instances ) {
            my $instance_inner = $class_inner->{instance}{ $instance->name }
              = { time => $instance->time->as_hashref };

            $self->_populate_control_timing_data(
                $instance_inner, $instance,
                qw( test_startup test_shutdown )
            );

            for my $method ( $instance->all_test_methods ) {
                my $method_inner = $instance_inner->{method}{ $method->name }
                  = { time => $method->time->as_hashref };

                $self->_populate_control_timing_data(
                    $method_inner, $method,
                    qw( test_setup test_teardown ),
                );
            }
        }
    }

    return \%t;
}

sub _populate_control_timing_data {
    my $self    = shift;
    my $hashref = shift;
    my $report  = shift;

    for my $control (@_) {
        my $control_method = $report->${ \( $control . '_method' ) }
          or next;
        $hashref->{control}{$control}{time}
          = $control_method->time->as_hashref;
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=for Pod::Coverage plan

=begin comment

This is the code I used to generate the example in this module (plus a little
manual editing to move the time key to the top of each nested hashref). This
is based on the timing data from running basic.t.

my $t = $report->timing_data;
delete $t->{class}{'TestsFor::Basic::Subclass'};
delete $t->{class}{'TestsFor::Basic'}{instance}{'TestsFor::Basic'}{method}{test_reporting};
delete $t->{class}{'TestsFor::Basic'}{instance}{'TestsFor::Basic'}{method}{test_this_baby};
use Devel::Dwarn; Dwarn _fudge($t);

sub _fudge {
    my $t = shift;

    use Data::Visitor::Callback;

    Data::Visitor::Callback->new(
        hash => sub {
            shift;
            my $h = shift;

            for my $k ( grep { exists $h->{$_} } qw( real system user ) ) {
                if ($h->{$k} ) {
                    $h->{$k} *= 10_000;
                }
                else {
                    $h->{$k} = $h->{real} * ($k eq 'system' ? 0.15 : 0.85);
                }
            }

            return $h;
        },
    )->visit($t);

    return $t;
}

=end comment

=head1 SYNOPSIS

    use Test::Class::Moose::Runner;

    my $runner = Test::Class::Moose::Runner->new;
    $runner->runtests;
    my $report = $runner->test_report;

=head1 DESCRIPTION

When working with larger test suites, it's useful to have full reporting
information available about the test suite. The reporting features of
L<Test::Class::Moose> allow you to report on the number of test class instances and
methods run (and number of tests), along with timing information to help you
track down which tests are running slowly. You can even run tests on your
report information:

    #!/usr/bin/env perl
    use lib 'lib';
    use Test::Most;
    use Test::Class::Moose::Load qw(t/lib);
    my $test_suite = Test::Class::Moose->new;

    subtest 'run the test suite' => sub {
        $test_suite->runtests;
    };

    my $report = $test_suite->test_report;
    my $duration = $report->time->duration;
    diag "Test suite run time: $duration";

    foreach my $class (@c) {
        my $class_name = $class->name;
        subtest "report for class:$class_name" => sub {
            ok !$class->is_skipped, "class:$class_name was not skipped";
            ok $class->passed, "class:$class_name passed";

            my @i = $class->all_test_instances;
            is scalar @i, 1, "tested one instance for $class_name";

            foreach my $instance (@i) {
                my $instance_name = $instance->name;
                subtest "report for instance:$instance_name" => sub {
                    ok !$instance->is_skipped,
                      "instance:$instance_name was not skipped";
                    ok $instance->passed, "instance:$instance_name passed";

                    my @methods = $instance->all_test_methods;
                    is_deeply
                      [ sort map { $_->name } @methods ],
                      $expected_methods{$class_name},
                      "instance:$instance_name ran the expected methods";

                    foreach my $method (@methods) {
                        my $method_name = $method->name;
                        subtest "report for method:$method_name" => sub {
                            ok !$method->is_skipped,
                              "$method_name was not skipped";
                            cmp_ok $method->num_tests_run, '>', 0,
                              '... and some tests should have been run';
                            _test_report_time($method);
                        };
                    }
                };
            }
        };
    }

Reporting is currently in alpha. The interface is not guaranteed to be stable.

=head1 METHODS

The top level report object for the whole test suite is returned from the
L<Test::Class::Moose::Runner> object's C<test_report> method.

This object provides the following methods:

=head2 C<all_test_classes>

Returns an array of L<Test::Class::Moose::Report::Class> objects.

=head2 C<num_test_classes>

Integer. The number of test classes run.

=head2 C<num_test_instances>

Integer. The number of test instances run.

=head2 C<num_test_methods>

Integer. The number of test methods that the runner tried to run.

=head2 C<num_tests_run>

Integer. The number of tests run.

=head2 C<current_class>

Returns the L<Test::Class::Moose::Report::Class> for the test class currently
being run, if it exists. This may return C<undef>.

=head2 C<current_instance>

Returns the L<Test::Class::Moose::Report::Instance> for the test class
instance currently being run, if it exists. This may return C<undef>.

=head2 C<current_method>

Returns the L<Test::Class::Moose::Report::Method> for the test method
currently being run, if one exists. This may return C<undef>.

=head2 C<time>

Returns a L<Test::Class::Moose::Report::Time> object. This object
represents the duration of the entire test suite.

=head2 C<timing_data>

Returns a complex nested hashref containing timing data for the entire test
run. This is primarily intended for serialization or shipping the data to code
in other languages. If you want to analyze timing data from the same process
as the test report, you might as well just use the Perl API.

See L</TIMING DATA STRUCTURE> for an example of the full structure.

At the top level of the data structure are two keys, C<time> and C<class>. The
C<time> key is replicated through different levels of the structure. It always
contains three keys:

    {   real   => 1.0001,
        system => 0.94,
        user   => 0.1,
    }

The C<class> key in turn contains a hashref keyed by class names. For each
class, there is a C<time> key and an C<instance> key.

The C<instance> key contains a hashref keyed on instance names. For each
instance, there is a hashref with C<time>, C<control>, and C<method> keys.

The C<control> key contains a hashref keyed on the control method names,
C<test_startup> and C<test_shutdown>. Each of those keys contains a hashref
containing C<time> key.

The C<method> keys are the names of the methods that were run for that test
instance. Each of those keys is in turn a hashref containing C<control> and
C<time> keys. The C<control> key contains a hashref keyed on the control
method names, C<test_setup> and C<test_teardown>.

=head1 TRUSTED METHODS

The following L<Test::Class::Moose::Report> methods are for internal use only
and are called by L<Test::Class::Moose>.  They are included here for those who
might want to hack on L<Test::Class::Moose>.

=head2 C<_inc_test_methods>

    $statistics->_inc_test_methods;        # increments by 1
    $statistics->_inc_test_methods($x);    # increments by $x

=head2 C<_inc_tests>

    $statistics->_inc_tests;        # increments by 1
    $statistics->_inc_tests($x);    # increments by $x

=head1 TIMING DATA STRUCTURE

Here's an example of what the entire timing data structure looks like:

    {   time => {
            real   => "90.2795791625977",
            system => "13.5419368743896",
            user   => 100
        },
        class => {
            "TestsFor::Basic" => {
                time => {
                    real   => "37.7511978149414",
                    system => "5.66267967224121",
                    user   => "32.0885181427002"
                },
                instance => {
                    "TestsFor::Basic" => {
                        time => {
                            real   => "27.4395942687988",
                            system => "4.11593914031982",
                            user   => "23.323655128479"
                        },
                        control => {
                            test_shutdown => {
                                time => {
                                    real   => "0.240802764892578",
                                    system => "0.0361204147338867",
                                    user   => "0.204682350158691"
                                },
                            },
                            test_startup => {
                                time => {
                                    real   => "0.360012054443359",
                                    system => "0.0540018081665039",
                                    user   => "0.306010246276855"
                                },
                            },
                        },
                        method => {
                            test_me => {
                                time => {
                                    real   => "4.6992301940918",
                                    system => "0.70488452911377",
                                    user   => "3.99434566497803"
                                },
                                control => {
                                    test_setup => {
                                        time => {
                                            real   => "0.510215759277344",
                                            system => "0.0765323638916016",
                                            user   => "0.433683395385742"
                                        },
                                    },
                                    test_teardown => {
                                        time => {
                                            real   => "0.269412994384766",
                                            system => "0.0404119491577148",
                                            user   => "0.229001045227051"
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
    }

=cut
