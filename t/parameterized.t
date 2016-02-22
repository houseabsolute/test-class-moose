#!/usr/bin/env perl
use Test::Most;
use lib 'lib';
use Test::Class::Moose::Load qw(t/parameterizedlib);
use Test::Class::Moose::Runner;
use TestsFor::Parameterized;

my $runner = Test::Class::Moose::Runner->new;

is_deeply(
    [   sort  { $a cmp $b }
          map { $_->test_instance_name }
          TestsFor::Parameterized->_tcm_make_test_class_instances
    ],
    [   'TestsFor::Parameterized with bar', 'TestsFor::Parameterized with foo'
    ],
    'test_instance_name returns the correct name for each instance'
);

subtest 'parameterized tests' => sub {
    $runner->runtests;
};

my $report = $runner->test_report;

my %expected = (
    'TestsFor::Parameterized with foo::test_one_set' => {
        planned => 1,
        ran     => 1,
    },
    'TestsFor::Parameterized with bar::test_one_set' => {
        planned => 1,
        ran     => 1,
    },
);

my %got;
foreach my $class ( $report->all_test_classes ) {
    foreach my $instance ( $class->all_test_instances ) {
        foreach my $method ( $instance->all_test_methods ) {
            my $fq_name = join '::' => $instance->name, $method->name;
            $got{$fq_name} = {
                planned => $method->tests_planned,
                ran     => $method->num_tests_run,
            };
        }
    }
}

is_deeply(
    [ sort keys %got ],
    [ sort keys %expected ],
    'reports include the expected test methods',
);

for my $name ( sort keys %expected ) {
    is_deeply(
        $got{$name},
        $expected{$name},
        "planned tests and number of tests run match for $name",
    );
}

done_testing;
