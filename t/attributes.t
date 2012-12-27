#!/usr/bin/env perl
use Test::Most;
use lib 'lib';
use Test::Class::Moose::Load qw(t/lib);

my $test_suite = Test::Class::Moose->new(
    {   show_timing => 0,
        statistics  => 1,
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
    eq_or_diff [ $class->new( $test_suite->configuration->args )
          ->get_test_methods ], $methods_for{$class},
      "$class should have the correct test methods";
}
my @tests;
subtest 'runtests' => sub {
    $test_suite->runtests;
    @tests = $test_suite->configuration->builder->details;
};

$test_suite = Test::Class::Moose->new(
    {   show_timing => 0,
        statistics  => 1,
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
    eq_or_diff [ $class->new( $test_suite->configuration->args )
          ->get_test_methods ], $methods_for{$class},
      "$class should have the correct test methods";
}
subtest 'runtests' => sub {
    $test_suite->runtests;
    @tests = $test_suite->configuration->builder->details;
};
show \@tests;
done_testing;
