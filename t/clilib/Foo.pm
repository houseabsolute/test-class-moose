package Foo;

use Test::Class::Moose bare => 1;

use Test2::V0 '!meta';

our $LOADED = 1;

sub test_foo {
    ok(1);
}

1;
