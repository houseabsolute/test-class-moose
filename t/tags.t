use strict;
use warnings;

use Test2::V0;
use Test::Class::Moose ();    # prevents us from inheriting from it
sub registry () {'Test::Class::Moose::AttributeRegistry'}

use FindBin qw( $Bin );
use Test::Class::Moose::Load "$Bin/taglib";
use Test::Class::Moose::Runner;

subtest 'Multiple included tags' => sub {

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
            'TestsFor::Basic::WithRole' => [
                qw/
                  test_in_a_role_with_tags
                  /
            ],
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
            'TestsFor::Basic::WithRole' => [
                qw/
                  test_in_a_role
                  test_in_a_role_with_tags
                  test_in_withrole
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
            'TestsFor::Basic::WithRole' => [],
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
            'TestsFor::Basic::WithRole' => [],
        }
    );
  };

sub _run_tests {
    my ( $new, $methods_for ) = @_;
    my $runner       = Test::Class::Moose::Runner->new($new);
    my @test_classes = sort $runner->test_classes;

    foreach my $class (@test_classes) {
        ## no critic (Subroutines::ProtectPrivateSubs)
        is( [ $runner->_executor->_test_methods_for( $class->new ) ],
            $methods_for->{$class},
            "$class should have the correct test methods"
        );
    }
}

subtest 'Verify Report' => sub {

    my $instance = Test::Class::Moose::Report::Instance->new(
        { name => 'TestsFor::Basic' } );
    my $method = Test::Class::Moose::Report::Method->new(
        { name => 'test_me', instance => $instance } );

    ok lives {
        ok $method->has_tag('first'),
          'has_tag() should tell us if we have a given tag'
    }, 'and not die';
    ok lives {
        ok !$method->has_tag('no_such_tag'),
          'has_tag() should tell us if we do not have a given tag'
    }, 'and not die';
};

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

    ok registry->class_has_tag( 'TestsFor::Basic::Subclass', 'second' ),
      'The tag registry should report if a class has a method with a given tag';

    ok !registry->class_has_tag( 'TestsFor::Basic::Subclass', 'no such tag' ),
      '... or if it does not';
};

## no critic (BuiltinFunctions::ProhibitStringyEval, ErrorHandling::RequireCheckingReturnValueOfEval)
eval <<'END';
    package TestsFor::Bad::Example;
    use Test::Class::Moose;

    sub test_setup : Test {
        my $test = shift;
        pass 'does not matter';
    }

    sub test_something { ok 1 }
END

my $error = $@;
like $error,
  qr/Test control method 'test_setup' may not have a Test attribute/,
  'Putting test attributes on a test control method should be a fatal error';

done_testing;
