# straight from TCM POD
package TestsFor::DateTime;
use Test::Class::Moose;
use DateTime;

# methods that begin with test_ are test methods.
sub test_constructor {
    my $test = shift;
    $test->test_report->plan(3);    # strictly optional

    can_ok 'DateTime', 'new';
    my %args = (
        year  => 1967,
        month => 6,
        day   => 20,
    );
    isa_ok my $date = DateTime->new(%args), 'DateTime';
    is $date->year, $args{year}, '... and the year should be correct';
}

1;
