#!/usr/bin/env perl
use Test::Most;
use lib 'lib';
use Test::Class::Moose::Load qw(t/skiplib);

my $test_suite = Test::Class::Moose->new;

subtest 'skip' => sub {
    $test_suite->runtests;
};

my $classes = $test_suite->test_report->test_classes;
is $classes->[0]->name, 'TestsFor::Basic',
  'Our first class should be listed in reporting';
ok $classes->[0]->is_skipped, '... and it should be listed as skipped';
explain $classes->[0]->skipped;    # the skip reason

is $classes->[1]->name, 'TestsFor::SkipSomeMethods',
  'Our second class should be listed in reporting';
ok !$classes->[1]->is_skipped, '... and it should NOT be listed as skipped';
my $methods = $classes->[1]->test_methods;

is @$methods, 3, '... and it should have three test methods';

my @skipped = grep { $_->is_skipped } @$methods;
is scalar @skipped, 1,
  '... and the correct number of methods should be skipped';
is $skipped[0]->name, 'test_me',
    '... and they should be the correct methods';
is $skipped[0]->tests_run, 0,
    '... and we should have 0 tests run';

done_testing;
