package TestsFor::Attributes;

use Test::Class::Moose;

sub test_just_one_test : Test {
    my $test = shift;
    pass 'We should only have a single test';
}

sub test_more_than_one_test : Tests(2) {
    my $test = shift;
    pass 'This is our first test';
    pass 'This is our second test';
}

sub test_with_attribute_but_no_plan : Tests {
    my $test = shift;

    pass "This is test number $_" for 1 .. 5;
}

sub this_is_a_test_method_because_of_the_attribute : Tests(3) {
    pass "These tests work: $_" for 1 .. 3;
}

1;
