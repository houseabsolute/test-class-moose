#!/usr/bin/env perl
use Test::Most;

use Test::Class::Moose ();

use Test::Builder;

BEGIN {
    plan skip_all => 'This test must always skip_all and must never fail'
      if 1;
}
