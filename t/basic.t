#!/usr/bin/env perl
use Test::Most;
use lib 'lib';
use lib 't/lib/';
use TestsFor::Basic;
use TestsFor::Basic::Subclass;

subtest 'basic tests' => sub {
    TestsFor::Basic->new( { show_timing => 1 } )->runtests;
};

done_testing;
