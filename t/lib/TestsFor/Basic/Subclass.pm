package TestsFor::Basic::Subclass;
use Test::Class::Moose parent => 'TestsFor::Basic';

sub test_me {
    my $test  = shift;
    my $class = $test->this_class;
    ok 1, "I overrode my parent! ($class)";
}

before 'test_this_baby' => sub {
    my $test  = shift;
    my $class = $test->this_class;
    pass "This should run before my parent method ($class)";
};

sub this_should_not_run {
    my $test = shift;
    fail "We should never see this test";
}

sub test_this_should_be_run {
    for ( 1 .. 5 ) {
        pass "This is test number $_ in this method";
    }
}

1;
