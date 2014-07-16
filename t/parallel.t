#!/usr/bin/env perl
use Test::Requires {
    'Parallel::ForkManager' => 0,
};

use Test::Most;
use lib 'lib';
use Carp::Always;
use Test::Class::Moose::Load qw(t/parallellib);
use Test::Class::Moose::Runner;

plan skip_all =>
    'These tests currently fail on Windows for reasons we do not understand. Patches welcome.'
    if $^O =~ /Win32/;

my $test_runner = Test::Class::Moose::Runner->new(
    show_timing => 0,
    jobs        => 2,
    statistics  => 0,
);

$test_runner->runtests;
