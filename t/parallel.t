#!/usr/bin/env perl
use Test::Most;
use lib 'lib';
use Carp::Always;
use Test::Class::Moose::Load qw(t/parallellib);

eval "use Parallel::ForkManager";
if ( my $error = $@ ) {
    plan skip_all => "Parallel::ForkManager not found: $@";
}
my $jobs = $ENV{NUM_JOBS} || 0;
$jobs = 1 if $jobs < 2;
if ( 1 == $jobs ) {
    diag "set NUM_JOBS=\$num_jobs to test this with more than one job";
}

my $test_suite = MyParallelTests->new(
    show_timing => 0,
    jobs        => $jobs,
    statistics  => 0,
);

$test_suite->runtests;

