#!/usr/bin/env perl
use Test::Most;
use lib 'lib';
use Test::Class::Moose::Load qw(t/skiplib);

my $test_suite = Test::Class::Moose->new;

subtest 'skip' => sub {
    $test_suite->runtests;
};
done_testing;
__END__

my %methods_for = (
    'TestsFor::Basic'           => [qw/test_me test_this_baby/],
    'TestsFor::Basic::Subclass' => [
        qw/
          test_me
          test_this_baby
          test_this_should_be_run
          /
    ],
);
my @test_classes = sort $test_suite->test_classes;
eq_or_diff \@test_classes, [ sort keys %methods_for ],
  'test_classes() should return a sorted list of test classes';

foreach my $class (@test_classes) {
    eq_or_diff [ $class->new->test_methods ], $methods_for{$class},
      "$class should have the correct test methods";
}

subtest 'test suite' => sub {
    $test_suite->runtests;
};

TestsFor::Basic::Subclass->meta->add_method(
    'test_this_will_die' => sub { die 'forced die' },
);
my $builder = $test_suite->test_configuration->builder;
$builder->todo_start('testing a dying test');
my @tests;
$test_suite = Test::Class::Moose->new;
subtest 'test_this_will_die() dies' => sub {
    $test_suite->runtests;
    @tests = $test_suite->test_configuration->builder->details;
};
$builder->todo_end;

my @expected_tests = (
    {   'actual_ok' => 1,
        'name'      => 'TestsFor::Basic',
        'ok'        => 1,
        'reason'    => '',
        'type'      => ''
    },
    {   'actual_ok' => 0,
        'name'      => 'TestsFor::Basic::Subclass',
        'ok'        => 0,
        'reason'    => '',
        'type'      => ''
    }
);
eq_or_diff \@tests, \@expected_tests,
  'Dying test methods should fail but not kill the test suite';

done_testing;
