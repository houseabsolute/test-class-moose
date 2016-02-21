#!/usr/bin/env perl

use lib 'lib', 't/lib';

use Test::Deep qw( bool );
use Test::Events;
use Test::Most;

use Test2::API qw( intercept );
use Test::Class::Moose::Load qw(t/lib);
use Test::Class::Moose::Runner;

my $runner = Test::Class::Moose::Runner->new( show_timing => 0 );

my %methods_for = (
    'TestsFor::Basic' => [qw/test_me test_reporting test_this_baby/],
    'TestsFor::Basic::Subclass' => [
        qw/
          test_me
          test_reporting
          test_this_baby
          test_this_should_be_run
          /
    ],
);
my @test_classes = sort $runner->test_classes;
eq_or_diff \@test_classes, [ sort keys %methods_for ],
  'test_classes() should return a sorted list of test classes';

foreach my $class (@test_classes) {
    eq_or_diff [ sort $class->new->test_methods ], $methods_for{$class},
      "$class should have the correct test methods";
}

subtest(
    'events from runner',
    sub {
        is_events(
            intercept { $runner->runtests },
            Plan => { max => 2 },
            TestsFor::Basic->expected_test_events,
            TestsFor::Basic::Subclass->expected_test_events,
        );
    }
);

TestsFor::Basic::Subclass->meta->add_method(
    'test_this_will_die' => sub { die 'forced die' },
);

my @subclass_events = TestsFor::Basic::Subclass->expected_test_events;
$subclass_events[5][0]{pass} = bool(0);
$subclass_events[5][2]{max}++;

push @{ $subclass_events[5] }, (
    Note => { message => 'TestsFor::Basic::Subclass->test_this_will_die()' },
    Note => { message => 'test_this_will_die' },
    Subtest => [
        {   name => 'test_this_will_die',
            pass => bool(0),
        },
    ],
    Diag => { message => qr{\QFailed test 'test_this_will_die'\E.+}s },
    Diag => { message => qr{\QCaught exception in subtest:\E.+}s },
);

push @subclass_events, (
    Diag => { message => qr{\QFailed test 'TestsFor::Basic::Subclass'\E.+}s },
);

subtest(
    'events from runner when a test dies',
    sub {
        is_events(
            intercept { $runner->runtests },
            Plan => { max => 2 },
            TestsFor::Basic->expected_test_events,
            @subclass_events,
        );
    }
);

done_testing;
