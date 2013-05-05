package TestsFor::Person::Employee;
use Test::Class::Moose extends => 'TestsFor::Person';

package TestsFor::Person::Employee;
use Test::Class::Moose extends => 'TestsFor::Person';

sub extra_constructor_args {
    return ( employee_number => 666 );
}

BEGIN {
    after 'test_person' => sub {
        my ( $test, $report ) = @_;
        $report->add_to_plan(1);
        is $test->test_fixture->employee_number, 666,
          '... and we should get the correct employee number';
    };
}

1;
