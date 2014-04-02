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
explain $report->time->duration;

foreach my $class ( $report->all_test_instances ) {
    my $class_name = $class->name;
    ok !$class->is_skipped, "$class_name was not skipped";

    subtest "$class_name methods" => sub {
        foreach my $method ( $class->all_test_methods ) {
            my $method_name = $method->name;
            ok !$method->is_skipped, "$method_name was not skipped";
            cmp_ok $method->num_tests_run, '>', 0,
              '... and some tests should have been run';
            explain "Run time for $method_name: ".$method->time->duration;
        }
    };
    can_ok $class, 'time';
    my $time = $class->time;
    isa_ok $time, 'Test::Class::Moose::Report::Time', 
    '... and the object it returns';
    foreach my $method (qw/real user system/) {
        ok looks_like_number( $time->$method ),
          "... and its '$method()' method should return a number";
    }
    explain "Run time for $class_name: ".$time->duration;
}
explain "Number of test instances: " . $report->num_test_instances;
explain "Number of test methods: "   . $report->num_test_methods;
explain "Number of tests:        "   . $report->num_tests_run;

done_testing;
