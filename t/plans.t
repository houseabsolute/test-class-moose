#!/usr/bin/env perl
use Test::Most 'bail';
use lib 'lib';
use Carp::Always;
use Test::Class::Moose::Runner::Sequential;

{
    BEGIN { $INC{'Person.pm'} = 1 }
    package Person;
    use Moose;
    has [qw/first_name last_name/] => ( is => 'ro' );
    
    sub full_name {
        my $self = shift;
        return join ' ' => $self->first_name, $self->last_name;
    }
}
{
    BEGIN { $INC{'Person/Employee.pm'} = 1 }
    package Person::Employee;

    use Moose;
    extends 'Person';

    has 'employee_number' => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );
}

use Test::Class::Moose::Load qw(t/planlib);

my $runner = Test::Class::Moose::Runner::Sequential->new;
subtest 'run the test suite' => sub {
    my $builder = Test::Builder->new;
    $builder->todo_start('deliberately bad plans');
    $runner->runtests;
    $builder->todo_end;
};

my $report = $runner->test_report;

# XXX test_with_attribute_but_no_plan didn't really report a plan of five, but
# this value gets set after the test is run.
my %expected_tests_planned = (
    'TestsFor::Person::test_person'                         => 2,
    'TestsFor::Person::Employee::test_person'               => 3,
    'TestsFor::Attributes::test_just_one_test'              => 1,
    'TestsFor::Attributes::test_more_than_one_test'         => 2,
    'TestsFor::Attributes::test_with_attribute_but_no_plan' => 5,
    'TestsFor::Attributes::this_is_a_test_method_because_of_the_attribute' =>
      3,
    'TestsFor::Attributes::Subclass::test_just_one_test'              => 1,
    'TestsFor::Attributes::Subclass::test_more_than_one_test'         => 3,
    'TestsFor::Attributes::Subclass::test_with_attribute_but_no_plan' => 3,
    'TestsFor::Attributes::Subclass::this_is_a_test_method_because_of_the_attribute'
      =>
      3,
);
my %expected_tests_run = (
    'TestsFor::Person::test_person'                         => 1,
    'TestsFor::Person::Employee::test_person'               => 2,
    'TestsFor::Attributes::test_just_one_test'              => 1,
    'TestsFor::Attributes::test_more_than_one_test'         => 2,
    'TestsFor::Attributes::test_with_attribute_but_no_plan' => 5,
    'TestsFor::Attributes::this_is_a_test_method_because_of_the_attribute' =>
      3,
    'TestsFor::Attributes::Subclass::test_just_one_test'              => 1,
    'TestsFor::Attributes::Subclass::test_more_than_one_test'         => 3,
    'TestsFor::Attributes::Subclass::test_with_attribute_but_no_plan' => 3,
    'TestsFor::Attributes::Subclass::this_is_a_test_method_because_of_the_attribute'
      =>
      5,
);
foreach my $instance ( $report->all_test_instances ) {
    foreach my $method ( $instance->all_test_methods ) {
        my $fq_name = join '::' => $instance->name, $method->name;
        is $method->tests_planned, $expected_tests_planned{$fq_name},
            "$fq_name should have $expected_tests_planned{$fq_name} tests planned";
        is $method->num_tests_run, $expected_tests_run{$fq_name},
            "$fq_name should have $expected_tests_run{$fq_name} tests run";
    }
}

done_testing;
