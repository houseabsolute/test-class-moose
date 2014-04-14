#!/usr/bin/env perl
use Test::Most;
use lib 'lib';
use Test::Class::Moose::Load qw(t/lib);
use Test::Class::Moose::Runner::Sequential;

my $runner = Test::Class::Moose::Runner::Sequential->new(
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
my @test_classes = sort $runner->test_classes;

foreach my $class (@test_classes) {
    eq_or_diff
      [ $runner->_tcm_test_methods_for_instance( $class->new ) ],
      $methods_for{$class},
      "$class should have the correct test methods";
}
my @tests;
subtest 'runtests' => sub {
    $runner->runtests;
    @tests = $runner->test_configuration->builder->details;
};

ok my $report = $runner->test_report,
  'We should be able to fetch reporting information from the test suite';
isa_ok $report, 'Test::Class::Moose::Report',
  '... and the object it returns';
is $report->num_test_instances, 2,
  '... and it should return the correct number of test class instances';
is $report->num_test_methods, 2,
  '... and the correct number of test methods';
is $report->num_tests_run, 7, '... and the correct number of tests';

$runner = Test::Class::Moose::Runner::Sequential->new(
    {   show_timing => 0,
        statistics  => 0,
        exclude     => qr/baby/,
    }
);

%methods_for = (
    'TestsFor::Basic'           => [qw/test_me test_reporting/],
    'TestsFor::Basic::Subclass' => [
        qw/
          test_me
          test_reporting
          test_this_should_be_run
          /
    ],
);

foreach my $class (@test_classes) {
    eq_or_diff
        [ $runner->_tcm_test_methods_for_instance( $class->new ) ],
        $methods_for{$class},
        "$class should have the correct test methods";
}
subtest 'runtests' => sub {
    $runner->runtests;
    @tests = $runner->test_configuration->builder->details;
};

ok $report = $runner->test_report,
  'We should be able to fetch reporting information from the test suite';
isa_ok $report, 'Test::Class::Moose::Report',
  '... and the object it returns';
is $report->num_test_instances, 2,
  '... and it should return the correct number of test class instances';
is $report->num_test_methods, 5,
  '... and the correct number of test methods';
is $report->num_tests_run, 18, '... and the correct number of tests';

done_testing;
