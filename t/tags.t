#!/usr/bin/env perl
use Test::Most 'bail';
use lib 'lib';

use Test::Class::Moose ();    # prevents us from inheriting from it
sub registry () { 'Test::Class::Moose::TagRegistry' }

BEGIN {
    plan skip_all => 'Sub::Attribute not available. Cannot test tags'
      if $Test::Class::Moose::NO_CAN_HAZ_ATTRIBUTES;
}
use Test::Class::Moose::Load qw(t/taglib);

subtest 'Multiple inclued tags' => sub {

    # For TestsFor::Basic::Subclass, the method modifier for 'test_this_baby'
    # effectively overrides the base class method.
    _run_tests(
        { include_tags => [qw/first second/] },
        {   'TestsFor::Basic' => [
                qw/
                  test_augment
                  test_clear_tags
                  test_me
                  test_me_not_overridden
                  test_this_baby
                  /
            ],
            'TestsFor::Basic::Subclass' => [
                qw/
                  test_augment
                  test_me
                  test_me_not_overridden
                  test_this_baby
                  test_this_should_be_run
                  /
            ],
            'TestsFor::MultipleExclude' => [],
        }
    );
};

subtest 'Simple exluded tag' => sub {
    _run_tests(
        { exclude_tags => [qw/first/] },
        {   'TestsFor::Basic' => [
                qw/
                  test_a_method_with_no_tags
                  test_this_baby
                  /
            ],
            'TestsFor::Basic::Subclass' => [
                qw/
                  test_a_method_with_no_tags
                  test_augment
                  test_clear_tags
                  test_this_baby
                  test_this_should_be_run
                  /
            ],
            'TestsFor::MultipleExclude' => [
                qw/
                  test_87801_1
                  test_87801_2
                  test_87801_3
                  /
            ],
        }
    );
};

subtest 'Simple included tag' => sub {
    _run_tests(
        { include_tags => [qw/third/] },
        {   'TestsFor::Basic'           => [],
            'TestsFor::Basic::Subclass' => [qw/ test_augment /],
            'TestsFor::MultipleExclude' => [],
        }
    );
};

subtest
  'Multiple excluded tags with single included tag (should be ANDed instead of ORed)'
  => sub {

    # https://rt.cpan.org/Ticket/Display.html?id=87801
    _run_tests(
        {   include_tags => ['ALL'],
            exclude_tags => [ '001', '002' ]
        },
        {   'TestsFor::Basic'           => [],
            'TestsFor::Basic::Subclass' => [],
            'TestsFor::MultipleExclude' => [qw/test_87801_3/],
        }
    );
  };

sub _run_tests {
    my ( $new, $methods_for ) = @_;
    my $test_suite   = Test::Class::Moose->new($new);
    my @test_classes = sort $test_suite->test_classes;

    foreach my $class (@test_classes) {
        eq_or_diff [ $class->new( $test_suite->test_configuration->args )
              ->test_methods ],
          $methods_for->{$class},
          "$class should have the correct test methods";
    }
}

subtest 'Verify registry' => sub {
    ok registry->method_has_tag(
        'TestsFor::Basic::Subclass', 'test_augment',
        'second'
      ),
      'The tag registry should report if a method has a particular tag';
    ok !registry->method_has_tag(
        'TestsFor::Basic::Subclass', 'test_augment',
        'first'
      ),
      '... or if it does not';

    ok registry->class_has_tag('TestsFor::Basic::Subclass', 'second'),
        'The tag registry should report if a class has a method with a given tag';

    ok !registry->class_has_tag('TestsFor::Basic::Subclass', 'no such tag'),
        '... or if it does not';
};

done_testing;
