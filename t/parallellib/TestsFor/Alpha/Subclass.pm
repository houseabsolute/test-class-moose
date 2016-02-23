package TestsFor::Alpha::Subclass;

use Test::Class::Moose extends => 'TestsFor::Alpha';

sub test_another {
    ok 1;
}

1;
