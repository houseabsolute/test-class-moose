use strict;
use warnings;

use lib 't/lib';

use Test2::API qw( intercept );
use Test2::V0;
use Test2::Tools::Subtest qw( subtest_streamed );
use Test::Events;
use Test::Reporting qw( test_report );

use Test::Class::Moose::Load 't/controllib';
use Test::Class::Moose::Runner;

my $runner = Test::Class::Moose::Runner->new(
    {   show_timing => 0,
        statistics  => 0,
    }
);

subtest_streamed(
    'events from runner',
    sub {
        test_events_is(
            intercept { $runner->runtests },
            array {
                event Plan => sub {
                    call max => 2;
                };
                TestsFor::Control::SkipClass->expected_test_events;
                TestsFor::Control::SkipMethod->expected_test_events;
                end();
            }
        );
    }
);

my %expect = (
    num_tests_run      => 1,
    num_test_instances => 2,
    num_test_methods   => 1,
    classes            => {
        TestsFor::Control::SkipClass->expected_report,
        TestsFor::Control::SkipMethod->expected_report,
    },
);

test_report( $runner->test_report, \%expect );

done_testing();
