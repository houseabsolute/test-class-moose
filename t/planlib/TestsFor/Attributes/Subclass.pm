package TestsFor::Attributes::Subclass;

use Test::Class::Moose extends => 'TestsFor::Attributes';

sub test_just_one_test : Test {
    my $test = shift;
    pass 'We should only have a single test';
}

sub test_more_than_one_test : Tests(1) {
    my $test = shift;

    $test->next::method;
    pass 'Overriding and calling parent';
}

sub test_with_attribute_but_no_plan : Tests(3) {
    my $test = shift;

    pass "Overriding and not calling parent: $_" for 1 .. 3;
}

sub this_is_a_test_method_because_of_the_attribute : Tests {
    my $test = shift;
    $test->next::method;
    pass
      "Overriding and calling parent, but we don't have a plan and parent does: $_"
      for 1 .. 2;
}

1;
