#!/usr/bin/env perl
use Test::Most;
use lib 'lib';
use lib 't/lib/';
use TestsFor::Basic;
use TestsFor::Basic::Subclass;

Test::Class::Moose->new( { show_timing => 0 } )->runtests;

done_testing;
