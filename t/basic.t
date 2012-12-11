#!/usr/bin/env perl
use Test::Most;
use lib 'lib';
use lib 't/lib/';
use TestsFor::Basic;
ok 1;
TestsFor::Basic->runtests;
done_testing;
