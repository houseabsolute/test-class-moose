#!/usr/bin/env perl

use lib 'lib', 't/lib';

use Test2::API qw( intercept );
use Test2::V0;
use Test2::Tools::Subtest qw( subtest_streamed );
use Test::Events;
use Test::Reporting qw( test_report );

use Test::Class::Moose::Load qw(t/todolib);
use Test::Class::Moose::Runner;

my $runner = Test::Class::Moose::Runner->new( show_timing => 0 );

subtest_streamed(
    'events from runner',
    sub {
        test_events_is(
            intercept { $runner->runtests },
            array {
                event Plan => sub {
                    call max => 1;
                };
                TestsFor::Todo->expected_test_events;
                event Diag => sub {
                    call message => match qr{^\n?Failed test};

                };
                end();
            },
        );
    }
);

my %expect = (
    num_tests_run      => 3,
    num_test_instances => 1,
    num_test_methods   => 3,
    classes            => {
        TestsFor::Todo->expected_report,
    },
);

test_report( $runner->test_report, \%expect );

done_testing();
