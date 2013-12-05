package TestsFor::Alpha::Subclass;

use Test::Class::Moose extends => 'TestsFor::Alpha';

sub test_another {
    sleep 1;
    ok 1;
}

1;
