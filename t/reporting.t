#!/usr/bin/env perl
use lib 'lib';
use Test::Most;
use Test::Class::Moose::Load qw(t/lib);
my $test_suite = Test::Class::Moose->new;

subtest 'run the test suite' => sub {
    $test_suite->runtests;
};
my $reporting = $test_suite->reporting;

foreach my $class ( $reporting->all_test_classes ) {
    my $class_name = $class->name;
    ok !$class->is_skipped, "$class_name was not skipped";

    subtest "$class_name methods" => sub {
        foreach my $method ( $class->all_test_methods ) {
            my $method_name = $method->name;
            ok !$method->is_skipped, "$method_name was not skipped";
            cmp_ok $method->num_tests, '>', 0,
              '... and some tests should have been run';
            explain "Run time for $method_name: ".$method->duration;
        }
    };
    explain "Run time for $class_name: ".$class->duration;
}
explain "Number of test classes: " . $reporting->num_test_classes;
explain "Number of test methods: " . $reporting->num_test_methods;
explain "Number of tests:        " . $reporting->num_tests;

done_testing;
