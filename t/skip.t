#!/usr/bin/env perl

use lib 'lib', 't/lib';

use Test2::API qw( intercept );
use Test2::V0;
use Test::Events;
use Test::Reporting qw( test_report );

use Test::Class::Moose::Load qw(t/skiplib);
use Test::Class::Moose::Runner;

my $runner = Test::Class::Moose::Runner->new;

test_events_is(
    intercept { $runner->runtests },
    array {
        event Plan => sub {
            call max => 2;
        };
        TestsFor::SkipAll->expected_test_events;
        TestsFor::SkipSomeMethods->expected_test_events;
        end();
    },
    'got expected events for skip tests'
);

my %expect = (
    num_tests_run      => 2,
    num_test_instances => 2,
    num_test_methods   => 2,
    classes            => {
        TestsFor::SkipAll->expected_report,
        TestsFor::SkipSomeMethods->expected_report,
    },
);

test_report( $runner->test_report, \%expect );

done_testing;
