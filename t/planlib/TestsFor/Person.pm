package TestsFor::Person;

use Test::Class::Moose;
with 'Test::Class::Moose::Role::AutoUse';

has 'test_fixture' => ( is => 'rw' );

sub extra_constructor_args {}

sub test_setup {
    my $test = shift;
    $test->test_fixture($test->class_name->new(
        first_name => 'Bob',
        last_name  => 'Dobbs',
        $test->extra_constructor_args,
    ));
}

sub test_person {
    my $test = shift;
    $test->test_report->plan(2);
    is $test->test_fixture->full_name, 'Bob Dobbs',
        'Our full name should be correct';
}

1;
