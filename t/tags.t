#!/usr/bin/env perl
use Test::Most;
use lib 'lib';

use Test::Class::Moose (); # prevents us from inheriting from it
BEGIN {
    plan skip_all => 'Sub::Attribute not available. Cannot test tags'
        if $Test::Class::Moose::NO_CAN_HAZ_ATTRIBUTES;
}
use Test::Class::Moose::Load qw(t/taglib);

my $test_suite = Test::Class::Moose->new(
    include_tags => [qw/first second/],
);

# For TestsFor::Basic::Subclass, the method modifier for 'test_this_baby' effectively overrides the
# base class method. Since tags are not inherited (and probably shouldnt' be),
# this is the correct behavior.
my %methods_for = (
    'TestsFor::Basic'           => [qw/test_me test_me_not_overridden test_this_baby/],
    'TestsFor::Basic::Subclass' => [qw/test_this_should_be_run/],
);
my @test_classes = sort $test_suite->test_classes;

foreach my $class (@test_classes) {
    eq_or_diff [
        $class->new( $test_suite->test_configuration->args )->test_methods
      ],
      $methods_for{$class},
      "$class should have the correct test methods";
}

$test_suite = Test::Class::Moose->new(
    exclude_tags => [qw/first/],
);

%methods_for = (
    'TestsFor::Basic'           => [qw/test_a_method_with_no_tags test_this_baby/],
    'TestsFor::Basic::Subclass' => [qw/
        test_a_method_with_no_tags
        test_me
        test_me_not_overridden
        test_this_baby
        test_this_should_be_run
    /],
);
@test_classes = sort $test_suite->test_classes;

foreach my $class (@test_classes) {
    eq_or_diff [
        $class->new( $test_suite->test_configuration->args )->test_methods
      ],
      $methods_for{$class},
      "$class should have the correct test methods";
}

done_testing;
