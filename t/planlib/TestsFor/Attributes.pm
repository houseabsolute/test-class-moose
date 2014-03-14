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

1;
