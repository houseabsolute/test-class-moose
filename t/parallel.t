#!/usr/bin/env perl
use Test::Most;
use lib 'lib';
use Carp::Always;
use Test::Class::Moose::Load qw(t/parallellib);

my $test_suite = MyParallelTests->new(
    show_timing => 0,
    jobs        => 2,
);

TODO: {
    local $TODO = 'out of sequence tests, but we knew that';
    subtest 'parallel' => sub {
        $test_suite->runtests;
    };
}

done_testing;
