package TestsFor::Basic::Subclass;
use Test::Class::Moose extends => 'TestsFor::Basic';

sub test_me {
    my $test  = shift;
    my $class = $test->test_class;
    ok 1, "I overrode my parent! ($class)";
}

before 'test_this_baby' => sub {
    my $test  = shift;
    my $class = $test->test_class;
    pass "This should run before my parent method ($class)";
};

sub this_should_not_run : Tags(first) {
    fail "We should never see this test";
}

sub test_this_should_be_run : Tags(second) {
    for ( 1 .. 5 ) {
        pass "This is test number $_ in this method";
    }
}

sub test_augment : Tags( +third -first ) {
    my $test = shift;
    pass 'this should run with tags "second" or "third", but not "first"';
    my $method = $test->test_report->current_method;
    ok $method->has_tag('second'),
      'has_tag() should tell us if we have a given tag';
    ok $method->has_tag('third'),
      'has_tag() should tell us if we have a given tag';
    ok !$method->has_tag('first'),
      'has_tag() should tell us if we do not have a given tag';
}

sub test_clear_tags : Tags() {
    fail 'this should not run, because it has no tags';
}

1;
