package Foo;

use strict;
use warnings;
use namespace::autoclean;

use Test::Class::Moose bare => 1;

use Test2::V0 '!meta';

sub test_foo {
    ok(1);
}

1;
