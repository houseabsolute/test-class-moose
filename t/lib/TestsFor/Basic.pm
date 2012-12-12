package TestsFor::Basic;
use Test::Class::Moose;

sub test_me {
    ok 1, 'test_me() ran';
    sleep 2;
    ok 2, 'this is another test';
}

sub test_this_baby {
    is 2, 2, 'whee!';
}

1;
