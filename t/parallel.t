#!/usr/bin/env perl
use Test::Requires {
    'Parallel::ForkManager' => 0,
};

use Test::Most;
use lib 'lib';
use Carp::Always;
use Test::Class::Moose::Load qw(t/parallellib);
use Test::Class::Moose::Runner;

my $test_runner = Test::Class::Moose::Runner->new(
    show_timing => 0,
    jobs        => 2,
    statistics  => 0,
);

$test_runner->runtests;
