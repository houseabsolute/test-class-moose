#!/usr/bin/env perl

use lib 'lib', 't/lib';

use Test2::API qw( intercept );
use Test2::Tools::Basic qw( done_testing );
use Test2::Tools::Compare qw( array call end event F is T );
use Test::Events;
use Test::Reporting qw( test_report );

use Test::Class::Moose::Load qw(t/parameterizedlib);
use Test::Class::Moose::Runner;

my $runner = Test::Class::Moose::Runner->new;

is( [   sort  { $a cmp $b }
          map { $_->test_instance_name }
          TestsFor::Parameterized->_tcm_make_test_class_instances
    ],
    [   'TestsFor::Parameterized with bar', 'TestsFor::Parameterized with foo'
    ],
    'test_instance_name returns the correct name for each instance'
);

is( intercept { $runner->runtests },
    array {
        event Plan => sub {
            call max => 2;
        };
        TestsFor::Empty->expected_test_events;
        TestsFor::Parameterized->expected_test_events;
        end()
    },
    'got expected test events'
);

my %expect = (
    is_parallel        => F(),
    num_tests_run      => 2,
    num_test_instances => 2,
    num_test_methods   => 2,
    classes            => {
        TestsFor::Empty->expected_report,
        TestsFor::Parameterized->expected_report,
    },
);

test_report( $runner->test_report, \%expect );

done_testing;
