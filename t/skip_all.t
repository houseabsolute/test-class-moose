#!/usr/bin/env perl
use Test::Most;

#$ENV{TEST_CLASS_MOOSE_SKIP_RUNTESTS} = 1;

use Test::Class::Moose ();

use Test::Builder;

BEGIN {
    plan skip_all => 'This test must always skip_all and must never fail'
      if 1;
}
