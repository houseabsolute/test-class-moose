#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib', 't/lib';

use Test::Requires {
    'Parallel::ForkManager' => 0,
};

use Test2::API qw( intercept );
use Test2::V0;
use Test::Events;
use Test::Reporting qw( test_report );

use List::SomeUtils qw( first_index );
use Scalar::Util qw( blessed );
use Test::Class::Moose::Load
  qw( t/basiclib t/parallellib t/parameterizedlib t/skiplib t/todolib );
use Test::Class::Moose::Runner;

skip_all(
    'These tests currently fail on Windows for reasons we do not understand. Patches welcome.'
) if $^O =~ /Win32/;

my $runner = Test::Class::Moose::Runner->new(
    show_timing => 0,
    jobs        => 2,
    statistics  => 0,
);

my $events = intercept { $runner->runtests };

test_events_is(
    $events,
    array {
        # The todo tests produce some diags from their die events and these
        # are mixed into the Subtest events in an unpredictable order because
        # tests are run in parallel.
        filter_items {
            grep { !$_->isa('Test2::Event::Diag') } @_;
        };
        event Plan => sub {
            call max => 11;
        };
        event 'Subtest';
        event 'Subtest';
        event 'Subtest';
        event 'Subtest';
        event 'Subtest';
        event 'Subtest';
        event 'Subtest';
        event 'Subtest';
        event 'Subtest';
        event 'Subtest';
        event 'Subtest';
        end();
    },
    'parallel tests produces a plan followed by a series of subtest & diag events'
);

my @classes = qw(
  TestsFor::Alpha
  TestsFor::Alpha::Subclass
  TestsFor::Basic
  TestsFor::Basic::Subclass
  TestsFor::Beta
  TestsFor::Empty
  TestsFor::Parameterized
  TestsFor::SkipAll
  TestsFor::SkipSomeMethods
  TestsFor::Sequential
  TestsFor::Todo
);

for my $class (@classes) {
    test_events_like(
        $events,
        array {
            filter_items {
                my $i = first_index {
                    blessed($_)
                      && $_->isa('Test2::Event::Subtest')
                      && $_->name eq $class;
                }
                @_;
                return @_[ $i .. $#_ ];
            };
            $class->expected_test_events;
        },
        "parallel tests produce the events for $class"
    );
}

my %expect = (
    num_tests_run      => 47,
    num_test_instances => 11,
    num_test_methods   => 25,
    classes            => {
        map { $_->expected_report } @classes,
    },
);

test_report( $runner->test_report, \%expect );

done_testing();
