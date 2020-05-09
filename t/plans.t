use strict;
use warnings;

use FindBin qw( $Bin );
use lib "$Bin/lib";

use Test2::API qw( intercept );
use Test2::V0;
use Test::Events;

use Test::Class::Moose::Runner;

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

use Test::Class::Moose::Load "$Bin/planlib";

my $runner = Test::Class::Moose::Runner->new;

test_events_is(
    intercept { $runner->runtests },
    array {
        event Plan => sub {
            call max => 4;
        };
        TestsFor::Attributes->expected_test_events;
        TestsFor::Attributes::Subclass->expected_test_events;
        TestsFor::Person->expected_test_events;
        TestsFor::Person::Employee->expected_test_events;
        end();
    },
    'got expected test events'
);

my $report = $runner->test_report;

# XXX test_with_attribute_but_no_plan didn't really report a plan of five, but
# this value gets set after the test is run.
my %expected = (
    'TestsFor::Person::test_person' => {
        planned => 2,
        ran     => 1,
    },
    'TestsFor::Person::Employee::test_person' => {
        planned => 3,
        ran     => 2,
    },
    'TestsFor::Attributes::test_just_one_test' => {
        planned => 1,
        ran     => 1,
    },
    'TestsFor::Attributes::test_more_than_one_test' => {
        planned => 2,
        ran     => 2,
    },
    'TestsFor::Attributes::test_with_attribute_but_no_plan' => {
        planned => 5,
        ran     => 5,
    },
    'TestsFor::Attributes::this_is_a_test_method_because_of_the_attribute' =>
      { planned => 3,
        ran     => 3,
      },
    'TestsFor::Attributes::Subclass::test_just_one_test' => {
        planned => 1,
        ran     => 1,
    },
    'TestsFor::Attributes::Subclass::test_more_than_one_test' => {
        planned => 3,
        ran     => 3,
    },
    'TestsFor::Attributes::Subclass::test_with_attribute_but_no_plan' => {
        planned => 3,
        ran     => 3,
    },
    'TestsFor::Attributes::Subclass::this_is_a_test_method_because_of_the_attribute'
      => {
        planned => 3,
        ran     => 5,
      },
);

my %got;
foreach my $class ( $report->all_test_classes ) {
    foreach my $instance ( $class->all_test_instances ) {
        foreach my $method ( $instance->all_test_methods ) {
            my $fq_name = join '::' => $class->name, $method->name;
            $got{$fq_name} = {
                planned => $method->tests_planned,
                ran     => $method->num_tests_run,
            };
        }
    }
}

is( [ sort keys %got ],
    [ sort keys %expected ],
    'reports include the expected test methods',
);

for my $name ( sort keys %expected ) {
    is( $got{$name},
        $expected{$name},
        "planned tests and number of tests run match for $name",
    );
}

done_testing;
