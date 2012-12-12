package TestsFor::Basic::Subclass;
use Test::Class::Moose parent => 'TestsFor::Basic';

sub test_me {
    my $test  = shift;
    my $class = ref $test;
    ok 1, "I overrode my parent! ($class)";
}

before 'test_this_baby' => sub {
    my $test  = shift;
    my $class = ref $test;
    pass "This should run before my parent method ($class)";
};

sub this_should_not_run {
    my $test = shift;
    fail "We should never see this test";
}

sub test_this_should_be_run {
    pass "Another test method";
}

1;
