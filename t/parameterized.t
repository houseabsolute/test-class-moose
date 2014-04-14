#!/usr/bin/env perl
use Test::Most;
use lib 'lib';
use Test::Class::Moose::Load qw(t/parameterizedlib);
use Test::Class::Moose::Runner::Sequential;

my $runner = Test::Class::Moose::Runner::Sequential->new;

my @tests;
subtest 'parameterized tests' => sub {
    $runner->runtests;
    @tests = $runner->test_configuration->builder->details;
};

my $report = $runner->test_report;

my %expected_tests_planned = (
    'TestsFor::Parameterized with foo::test_one_set' => 1,
    'TestsFor::Parameterized with bar::test_one_set' => 1,
);
my %expected_tests_run = (
    'TestsFor::Parameterized with foo::test_one_set' => 1,
    'TestsFor::Parameterized with bar::test_one_set' => 1,
);

foreach my $instance ( $report->all_test_instances ) {
    foreach my $method ( $instance->all_test_methods ) {
        my $fq_name = join '::' => $instance->name, $method->name;
        is $method->tests_planned, $expected_tests_planned{$fq_name},
            "$fq_name should have $expected_tests_planned{$fq_name} tests planned";
        is $method->num_tests_run, $expected_tests_run{$fq_name},
            "$fq_name should have $expected_tests_run{$fq_name} tests run";
    }
}

done_testing;
