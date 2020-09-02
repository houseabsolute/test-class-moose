package TestsFor::Person::Employee;

use Test::Class::Moose extends => 'TestsFor::Person', bare => 1;

use Test2::Tools::Compare qw( array call end event is T );

sub extra_constructor_args {
    return ( employee_number => 666 );
}

BEGIN {
    after 'test_person' => sub {
        my $test = shift;
        $test->test_report->plan(1);
        is $test->test_fixture->employee_number, 666,
          '... and we should get the correct employee number';
    };
}

sub expected_test_events {
    event Note => sub {
        call message => 'TestsFor::Person::Employee';
    };
    event Subtest => sub {
        call name      => 'TestsFor::Person::Employee';
        call pass      => T();
        call subevents => array {
            event Plan => sub {
                call max => 1;
            };
            event Note => sub {
                call message => 'test_person';
            };
            event Subtest => sub {
                call name      => 'test_person';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call pass => T();
                        call name => 'Our full name should be correct';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name =>
                          '... and we should get the correct employee number';
                    };
                    event Plan => sub {
                        call max => 2;
                    };
                    end();
                };
            };
            end();
        };
    };
}

1;
