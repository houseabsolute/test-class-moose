use strict;
use warnings;
use lib '.';
use Test::Most;
use Test::Class::Moose::Load qw(t/reportpassedlib);
use Test::Class::Moose::Runner;

my $runner = Test::Class::Moose::Runner->new( show_timing => 0 );
TODO: {
    local $TODO = 'subtests return a fail if tests fail, even if in TODO';
    subtest 'foo' => sub {
        $runner->runtests;
    };
}
my $report = $runner->test_report;
explain $report->time->duration;

# note: because of a possible bug in Test::Builder::subtest returning a fail
# status, even if the test is TODO, we rely on that feature to make these
# tests easier: $report->passed reports false if a test failed, even if it's a
# TODO test.
my %passed = (
    'TestsFor::Fail' => {
        class   => 0,
        methods => {
            test_a_bad  => 0,
            test_a_good => 1,
            test_b_bad  => 0,
            test_b_good => 1,
        },
    },
    'TestsFor::FailChild' => {
        class   => 1,
        methods => {
            test_a_bad   => 1,
            test_a_good  => 1,
            test_another => 1,
            test_b_bad   => 1,
            test_b_good  => 1,
        },
    },
    'TestsFor::Pass' => {
        class   => 1,
        methods => {
            test_a_good   => 1,
            test_a_good_2 => 1,
            test_b_good   => 1,
            test_b_good_2 => 1,
        },
    },
);

foreach my $class ( $report->all_test_classes ) {
    my $class_name = $class->name;
    is $class->passed, $passed{$class_name}{class},
      "$class_name pass/fail status should be correct";

    foreach my $instance ( $class->all_test_instances ) {
        foreach my $method ( $instance->all_test_methods ) {
            my $method_name = $method->name;
            is $method->passed, $passed{$class_name}{methods}{$method_name},
              "$class_name\::$method_name pass/fail status should be correct";
            cmp_ok $method->num_tests_run, '>', 0,
              '... and some tests should have been run';
            explain "Run time for $method_name: " . $method->time->duration;
        }
        can_ok $instance, 'time';
        my $time = $instance->time;
        isa_ok $time, 'Test::Class::Moose::Report::Time',
          '... and the object it returns';

        my $instance_name = $instance->name;
        explain "Run time for $instance_name: " . $time->duration;
    }
}
done_testing;
