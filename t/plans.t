#!/usr/bin/env perl
use Test::Most;
use lib 'lib';
use Carp::Always;

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

my $test_suite = Test::Class::Moose->new;
subtest 'run the test suite' => sub {
    my $builder = Test::Builder->new;
    $builder->todo_start('deliberately bad plans');
    $test_suite->runtests;
    $builder->todo_end;
};

my $report = $test_suite->test_reporting;
my %expected_planned_tests = (
    'TestsFor::Person::test_person'           => 2,
    'TestsFor::Person::Employee::test_person' => 3,
);
foreach my $class ( $report->all_test_classes ) {
    foreach my $method ( $class->all_test_methods ) {
        my $fq_name = join '::' => $class->name, $method->name;
        is $method->num_tests, $expected_planned_tests{$fq_name},
            "$fq_name should have $expected_planned_tests{$fq_name} tests planned";
    }
}

done_testing;
