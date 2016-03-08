#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib', 't/lib';

use Test::Requires {
    'Parallel::ForkManager' => 0,
};

use Test2::API qw( intercept );
use Test2::Tools::Basic qw( done_testing plan );
use Test2::Tools::Compare qw( array call end event filter_items is );
use Test::Events;

use List::SomeUtils qw( first_index );
use Scalar::Util qw( blessed );
use Test::Class::Moose::Load qw( t/basiclib t/parallellib t/parameterizedlib t/skiplib );
use Test::Class::Moose::Runner;

plan skip_all =>
  'These tests currently fail on Windows for reasons we do not understand. Patches welcome.'
  if $^O =~ /Win32/;

my $test_runner = Test::Class::Moose::Runner->new(
    show_timing => 0,
    jobs        => 2,
    statistics  => 0,
);

my $events = intercept { $test_runner->runtests };

test_events_is(
    $events,
    array {
        event Plan => sub {
            call max => 10;
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
        end();
    },
    'parallel tests produces a plan followed by 6 subtests events'
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

done_testing();
