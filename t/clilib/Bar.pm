package Bar;

use Test::Class::Moose bare => 1;

use Test2::V0 '!meta';

sub test_bar {
    ok(1);
}

1;
