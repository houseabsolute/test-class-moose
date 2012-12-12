package TestsFor::Basic::Subclass;
use Test::Class::Moose parent => 'TestsFor::Basic';

sub test_me {
    ok 1, 'I overrode my parent!';
}

before 'test_this_baby' => sub {
    pass "This should run before my parent method";
};

1;
