#!/usr/bin/env perl
use Test::Most;
use lib 'lib';
use Test::Class::Moose::Load qw(t/lib);
use Test::Class::Moose::Runner::Sequential;

my $runner = Test::Class::Moose::Runner::Sequential->new(
    show_timing  => 0,
    test_classes => 'TestsFor::Basic',
);

my %methods_for = (
    'TestsFor::Basic' => [qw/test_me test_reporting test_this_baby/],
);
my @test_classes = sort $runner->test_classes;
eq_or_diff \@test_classes, [ sort keys %methods_for ],
  'test_classes() should return a sorted list of test classes';

foreach my $class (@test_classes) {
    eq_or_diff [ sort $class->new->test_methods ], $methods_for{$class},
      "$class should have the correct test methods";
}

subtest 'test suite' => sub {
    $runner->runtests;
};

done_testing;
