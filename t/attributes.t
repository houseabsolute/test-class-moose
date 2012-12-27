#!/usr/bin/env perl
use Test::Most;
use lib 'lib';
use Test::Class::Moose::Load qw(t/lib);

my $test_suite = Test::Class::Moose->new(
    {   show_timing => 0,
        statistics  => 0,
        include     => qr/baby/,
    }
);

my %methods_for = (
    'TestsFor::Basic'           => [qw/test_this_baby/],
    'TestsFor::Basic::Subclass' => [
        qw/
          test_this_baby
          /
    ],
);
my @test_classes = sort $test_suite->get_test_classes;

foreach my $class (@test_classes) {
    eq_or_diff [
        $class->new( $test_suite->configuration->args )->get_test_methods ],
      $methods_for{$class},
      "$class should have the correct test methods";
}
my @tests;
subtest 'runtests' => sub {
    $test_suite->runtests;
    @tests = $test_suite->configuration->builder->details;
};

ok my $statistics = $test_suite->statistics,
  'We should be able to fetch statistics information from the test suite';
isa_ok $statistics, 'Test::Class::Moose::Reporting',
  '... and the object it returns';
is $statistics->num_test_classes, 2,
  '... and it should return the correct number of test classes';
is $statistics->num_test_methods, 2,
  '... and the correct number of test methods';
is $statistics->num_tests, 3, '... and the correct number of tests';

$test_suite = Test::Class::Moose->new(
    {   show_timing => 0,
        statistics  => 0,
        exclude     => qr/baby/,
    }
);

%methods_for = (
    'TestsFor::Basic'           => [qw/test_me/],
    'TestsFor::Basic::Subclass' => [
        qw/
          test_me
          test_this_should_be_run
          /
    ],
);

foreach my $class (@test_classes) {
    eq_or_diff [
        $class->new( $test_suite->configuration->args )->get_test_methods ],
      $methods_for{$class},
      "$class should have the correct test methods";
}
subtest 'runtests' => sub {
    $test_suite->runtests;
    @tests = $test_suite->configuration->builder->details;
};

ok $statistics = $test_suite->statistics,
  'We should be able to fetch statistics information from the test suite';
isa_ok $statistics, 'Test::Class::Moose::Reporting',
  '... and the object it returns';
is $statistics->num_test_classes, 2,
  '... and it should return the correct number of test classes';
is $statistics->num_test_methods, 3,
  '... and the correct number of test methods';
is $statistics->num_tests, 8, '... and the correct number of tests';

done_testing;
