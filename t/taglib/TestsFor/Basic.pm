package TestsFor::Basic;

use strict;
use warnings;
use namespace::autoclean;

use Test::Class::Moose;

sub test_me : Tags( first second ) {
    my $test  = shift;
    my $class = ref $test;
    ok 1, "test_me() ran ($class)";
    ok 2, "this is another test ($class)";
    my $method = $test->test_report->current_method;
    ok $method->has_tag('first'),
      'has_tag() should tell us if we have a given tag';
    ok !$method->has_tag('no_such_tag'),
      'has_tag() should tell us if we do not have a given tag';
}

sub test_me_not_overridden : Tags(first) {
    ok 1, 'this test has a "first" tag but is not overridden or modified';
}

sub test_this_baby : Tags(second) {
    my $test  = shift;
    my $class = ref $test;
    is 2, 2, "whee! ($class)";
}

sub test_a_method_with_no_tags {
    ok 1, 'this test method has no tags';
}

sub test_augment : Tags(first second) {
    pass
      'this test has a "first" and "second" tag but it they will be overridden';
}

sub test_clear_tags : Tags(first) {
    pass
      'this test has the "first" tag, but it\'s going to get cleared in the subtest';
}

1;
