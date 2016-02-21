#!/usr/bin/env perl

use lib 'lib', 't/lib';

use Test::Deep qw( bool );
use Test::Events;
use Test::Most;

use Test2::API qw( intercept );
use Test::Class::Moose::Load 't/lib';
use Test::Class::Moose::Runner;

my $runner = Test::Class::Moose::Runner->new(
    {   show_timing => 0,
        statistics  => 0,
    }
);

_replace_subclass_method( test_startup => sub { my $test = shift } );
subtest(
    'events when test_startup does not die or run tests',
    sub {
        is_events(
            intercept { $runner->runtests },
            Plan => { max => 2 },
            TestsFor::Basic->expected_test_events,
            TestsFor::Basic::Subclass->expected_test_events,
        );
    }
);

_replace_subclass_method( test_startup => sub { die 'forced die' } );
subtest(
    'events when test_startup dies',
    sub {
        is_events(
            intercept { $runner->runtests },
            Plan => { max => 2 },
            TestsFor::Basic->expected_test_events,
            Note => {
                message => "\nRunning tests for TestsFor::Basic::Subclass\n\n"
            },
            Note => { message => 'TestsFor::Basic::Subclass' },
            Subtest => [
                {   name => 'TestsFor::Basic::Subclass',
                    pass => bool(0),
                },
                Ok => {
                    name => 'TestsFor::Basic::Subclass->test_startup failed',
                    pass => bool(0),
                },
                Diag => {
                    message =>
                      qr/\QFailed test 'TestsFor::Basic::Subclass->test_startup failed'\E.+/s,
                },
                Diag => {
                    message =>
                      qr/\Qforced die at t\E.\Qtest_control_methods.t\E.+/s
                },
                Plan => { max => 1 },
            ],
            Diag => {
                message => qr/\QFailed test 'TestsFor::Basic::Subclass'\E.+/s,
            },
        );
    }
);

_replace_subclass_method(
    test_startup => sub {
        pass();
    },
);
subtest(
    'events when test_startup runs tests',
    sub {
        is_events(
            intercept { $runner->runtests },
            Plan => { max => 2 },
            TestsFor::Basic->expected_test_events,
            Note => {
                message => "\nRunning tests for TestsFor::Basic::Subclass\n\n"
            },
            Note => { message => 'TestsFor::Basic::Subclass' },
            Subtest => [
                {   name => 'TestsFor::Basic::Subclass',
                    pass => bool(0),
                },
                Ok => {
                    name => undef,
                    pass => bool(1),
                },
                Ok => {
                    name => 'TestsFor::Basic::Subclass->test_startup failed',
                    pass => bool(0),
                },
                Diag => {
                    message =>
                      qr/\QFailed test 'TestsFor::Basic::Subclass->test_startup failed'\E.+/s,
                },
                Diag => {
                    message =>
                      qr/\QTests may not be run in test control methods (test_startup)\E.+/s,
                },
                Plan => { max => 2 },
            ],
            Diag => {
                message => qr/\QFailed test 'TestsFor::Basic::Subclass'\E.+/s
            },
        );
    }
);

done_testing;

sub _replace_subclass_method {
    my $name   = shift;
    my $method = shift;

    TestsFor::Basic::Subclass->meta->remove_method($name);
    TestsFor::Basic::Subclass->meta->add_method( $name => $method );
}

