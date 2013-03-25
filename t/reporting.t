#!/usr/bin/env perl
use lib 'lib';
use Test::Most;
use Scalar::Util 'looks_like_number';
use Test::Class::Moose::Load qw(t/lib);
my $test_suite = Test::Class::Moose->new;

subtest 'run the test suite' => sub {
    $test_suite->runtests;
};
my $reporting = $test_suite->test_reporting;

foreach my $class ( $reporting->all_test_classes ) {
    my $class_name = $class->name;
    ok !$class->is_skipped, "$class_name was not skipped";

    subtest "$class_name methods" => sub {
        foreach my $method ( $class->all_test_methods ) {
            my $method_name = $method->name;
            ok !$method->is_skipped, "$method_name was not skipped";
            cmp_ok $method->tests_run, '>', 0,
              '... and some tests should have been run';
            explain "Run time for $method_name: ".$method->time->duration;
        }
    };
    can_ok $class, 'time';
    my $time = $class->time;
    isa_ok $time, 'Test::Class::Moose::Reporting::Time', 
    '... and the object it returns';
    foreach my $method (qw/real user system/) {
        ok looks_like_number( $time->$method ),
          "... and its '$method()' method should return a number";
    }
    explain "Run time for $class_name: ".$time->duration;
}
explain "Number of test classes: " . $reporting->num_test_classes;
explain "Number of test methods: " . $reporting->num_test_methods;
explain "Number of tests:        " . $reporting->tests_run;

done_testing;
