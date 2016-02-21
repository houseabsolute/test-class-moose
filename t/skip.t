#!/usr/bin/env perl

use lib 'lib', 't/lib';

use Test::Deep qw( bool );
use Test::Events;
use Test::Most;

use Test2::API qw( intercept );
use Test::Class::Moose::Load qw(t/skiplib);
use Test::Class::Moose::Runner;

my $runner = Test::Class::Moose::Runner->new;

is_events(
    intercept { $runner->runtests },
    Plan => { max     => 2 },
    Note => { message => "\nRunning tests for TestsFor::Basic\n\n" },
    Note => { message => 'TestsFor::Basic' },
    Subtest => [
        {   name => 'TestsFor::Basic',
            pass => bool(1),
        },
        Plan => {
            directive => 'SKIP',
            reason    => 'all methods should be skipped',
            max       => 0,
        },
    ],
    Note =>
      { message => "\nRunning tests for TestsFor::SkipSomeMethods\n\n" },
    Note => { message => 'TestsFor::SkipSomeMethods' },
    Subtest => [
        {   name => 'TestsFor::SkipSomeMethods',
            pass => bool(1),
        },
        Plan => { max     => 3 },
        Note => { message => 'TestsFor::SkipSomeMethods->test_again()' },
        Note => { message => 'test_again' },
        Subtest => [
            {   name => 'test_again',
                pass => bool(1),
            },
            Ok => {
                name => 'in test_again',
                pass => bool(1),
            },
            Plan => { max => 1 },
        ],
        Note => { message => 'TestsFor::SkipSomeMethods->test_me()' },
        Note => { message => 'test_me' },
        Subtest => [
            {   name => 'test_me',
                pass => bool(1),
            },
            Plan => {
                directive => 'SKIP',
                reason => 'only methods listed as skipped should be skipped',
                max    => 0,
            },
        ],
        Note => { message => 'TestsFor::SkipSomeMethods->test_this_baby()' },
        Note => { message => 'test_this_baby' },
        Subtest => [
            {   name => 'test_this_baby',
                pass => bool(1),
            },
            Ok => {
                name => 'whee! (TestsFor::SkipSomeMethods)',
                pass => bool(1),
            },
            Plan => { max => 1 },
        ],
    ],
);

my $classes = $runner->test_report->test_classes;

{
    is $classes->[0]->name, 'TestsFor::Basic',
      'Our first class should be listed in reporting';

    my $instances = $classes->[0]->test_instances;

    ok $instances->[0]->is_skipped, '... and it should be listed as skipped';
    ok $instances->[0]->passed, '... and it is reported as passed';
    explain $instances->[0]->skipped;    # the skip reason
}

{
    is $classes->[1]->name, 'TestsFor::SkipSomeMethods',
      'Our second class should be listed in reporting';

    my $instances = $classes->[1]->test_instances;
    ok !$instances->[0]->is_skipped,
      '... and it should NOT be listed as skipped';
    ok $instances->[0]->passed, '... and it is reported as passed';
    my $methods = $instances->[0]->test_methods;

    is @$methods, 3, '... and it should have three test methods';

    my @skipped = grep { $_->is_skipped } @$methods;
    is scalar @skipped, 1,
      '... and the correct number of methods should be skipped';
    is $skipped[0]->name, 'test_me',
      '... and they should be the correct methods';
    is $skipped[0]->num_tests_run, 0,
      '... and we should have 0 tests run';
}

done_testing;
