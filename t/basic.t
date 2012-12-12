#!/usr/bin/env perl
use Test::Most;
use lib 'lib';
use Test::Class::Moose::Load qw(t/lib);

Test::Class::Moose->new(
    {   show_timing => 0,
        statistics  => 1,
    }
)->runtests;

done_testing;
