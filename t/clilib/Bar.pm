package Bar;

use Test::Class::Moose bare => 1;

use Test2::Bundle::Extended '!meta';

our $LOADED = 1;

sub test_bar {
    ok(1);
}

1;
