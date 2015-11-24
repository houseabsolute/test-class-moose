#!/usr/bin/env perl
use lib 'lib';
use Test::Most;
use Scalar::Util 'looks_like_number';
use Test::Class::Moose::Load qw(t/lib);
use Test::Class::Moose::Runner;

my $runner = Test::Class::Moose::Runner->new;

subtest 'run the test suite' => sub {
    $runner->runtests;
};
my $report = $runner->test_report;

ok !$report->is_parallel, 'report is not parallel';
is $report->num_test_instances, 2, '2 test instances';
is $report->num_test_methods,   7, '7 test methods';

my @c = $report->all_test_classes;
is_deeply
  [ sort map { $_->name } @c ],
  [ 'TestsFor::Basic', 'TestsFor::Basic::Subclass' ],
  'class reports have expected names';

my %expected_methods = (
    'TestsFor::Basic' => [qw( test_me test_reporting test_this_baby )],
    'TestsFor::Basic::Subclass' =>
      [qw( test_me test_reporting test_this_baby test_this_should_be_run )],
);

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

                _test_control_methods(
                    $instance,
                    qw( test_startup test_shutdown )
                );

                my @methods = $instance->all_test_methods;
                is_deeply
                  [ sort map { $_->name } @methods ],
                  $expected_methods{$class_name},
                  "instance:$instance_name ran the expected methods";

                foreach my $method (@methods) {
                    _test_control_methods(
                        $method,
                        qw( test_setup test_teardown )
                    );
                    my $method_name = $method->name;
                    subtest "report for method:$method_name" => sub {
                        ok !$method->is_skipped,
                          "$method_name was not skipped";
                        cmp_ok $method->num_tests_run, '>', 0,
                          '... and some tests should have been run';
                        _test_report_time($method);
                    };
                }

                _test_report_time($instance);
            };
        }

        _test_report_time($class);
    };
}

my $pos_or_zero = sub { looks_like_number( $_[0] ) && $_[0] >= 0 };
my %time_cmp = (
    time => {
        real   => code($pos_or_zero),
        system => code($pos_or_zero),
        user   => code($pos_or_zero),
    },
);

cmp_deeply(
    $report->timing_data,
    {   %time_cmp,
        class => {
            map { _class_cmp_deeply($_) } 'TestsFor::Basic',
            'TestsFor::Basic::Subclass',
        },
    },
    'timing_data contains expected data structure',
);

sub _class_cmp_deeply {
    my $class = shift;

    my %instance_control_cmp = (
        control => {
            test_startup  => \%time_cmp,
            test_shutdown => \%time_cmp,
        },
    );

    my %method_control_cmp = (
        control => {
            test_setup    => \%time_cmp,
            test_teardown => \%time_cmp,
        },
    );

    return (
        $class => {
            %time_cmp,
            instance => {
                $class => {
                    %time_cmp,
                    %instance_control_cmp,
                    method => {
                        map { $_ => { %time_cmp, %method_control_cmp } }
                          @{ $expected_methods{$class} },
                    },
                },
            },
        }
    );
}

explain 'Number of test classes:   ' . $report->num_test_instances;
explain 'Number of test instances: ' . $report->num_test_instances;
explain 'Number of test methods:   ' . $report->num_test_methods;
explain 'Number of tests:          ' . $report->num_tests_run;

done_testing;

sub _test_control_methods {
    my $report = shift;

    for my $control (@_) {
        subtest "control method:$control" => sub {
            my $report_meth = $control . '_method';
            my $method      = $report->$report_meth;
            isa_ok $method, 'Test::Class::Moose::Report::Method',
              $report_meth;
            is $method->name, $control,
              "$control method report name";
            is $method->num_tests_run, '0',
              "no tests run in $control";
            _test_report_time($method);
        };
    }
}

sub _test_report_time {
    my $report = shift;

    can_ok $report, 'time';
    my $time = $report->time;
    isa_ok $time, 'Test::Class::Moose::Report::Time',
      '... and the object it returns';
    foreach my $method (qw/real user system/) {
        ok looks_like_number( $time->$method ),
          qq{... and its '$method()' method should return a number};
        cmp_ok $time->$method, '>=', 0,
          '... greater than or equal to zero';
    }
    explain 'Run time = ' . $time->duration;
}

__END__

This is the code I used to generate the example in Test::Class::Moose::Report
(plus a little manual editing to move the time key to the top of each nested
hashref).

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
