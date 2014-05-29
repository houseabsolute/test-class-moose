#!/usr/bin/env perl
use Test::Requires {
    'Test::Output' => '0.005',
};

use Test::Most;
use Test::Warnings qw( warnings );

{
    package My::Runner;
    use Test::Class::Moose;
    with 'Test::Class::Moose::Role::Parallel';

    sub test_ok {
        ok(1);
    }
}

# We need to run the TCM ->runtests bit in a subtest because it issues a plan
# that would otherwise confuse the TAP output.
my @warnings;
subtest 'warnings', sub {
    @warnings = warnings { My::Runner->new->runtests() };
};

like(
    $warnings[0],
    qr/\QThe Test::Class::Moose::Role::Parallel role is deprecated. Use the new Test::Class::Moose::Runner::Parallel class instead./,
    'got a deprecation warning when using Test::Class::Moose::Role::Parallel'
);

done_testing;
