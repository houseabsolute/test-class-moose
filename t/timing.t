#!/usr/bin/env perl
use lib 'lib';

use Test2::API qw( intercept );
use Test2::Bundle::Extended;

use Test::Class::Moose::Load qw(t/timinglib);
use Test::Class::Moose::Runner;

my $runner = Test::Class::Moose::Runner->new(
    test_classes => 'TestFor::Timing',
);

intercept { $runner->runtests };

my $report = $runner->test_report;
cmp_ok(
    $report->end_time - $report->start_time, '>', 1,
    'difference between start and end time for report is > 1 second'
);

done_testing;
