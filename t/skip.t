#!/usr/bin/env perl
use Test::Most;
use lib 'lib';
use Test::Class::Moose::Load qw(t/skiplib);
use Test::Class::Moose::Runner;

my $runner = Test::Class::Moose::Runner->new;

subtest 'skip' => sub {
    $runner->runtests;
};

my $instances = $runner->test_report->test_instances;
is $instances->[0]->name, 'TestsFor::Basic',
  'Our first class should be listed in reporting';
ok $instances->[0]->is_skipped, '... and it should be listed as skipped';
explain $instances->[0]->skipped;    # the skip reason

is $instances->[1]->name, 'TestsFor::SkipSomeMethods',
  'Our second class should be listed in reporting';
ok !$instances->[1]->is_skipped, '... and it should NOT be listed as skipped';
my $methods = $instances->[1]->test_methods;

is @$methods, 3, '... and it should have three test methods';

my @skipped = grep { $_->is_skipped } @$methods;
is scalar @skipped, 1,
  '... and the correct number of methods should be skipped';
is $skipped[0]->name, 'test_me',
    '... and they should be the correct methods';
is $skipped[0]->num_tests_run, 0,
    '... and we should have 0 tests run';

done_testing;
