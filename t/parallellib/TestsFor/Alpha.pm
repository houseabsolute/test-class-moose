package TestsFor::Alpha;

use Test::Class::Moose;

sub test_alpha_first {
    my $test = shift;
    ok 1;
    sleep 1;
    ok 2;
    sleep 1;
}

sub test_second {
    my $test = shift;
    $test->test_report->plan(1);
    sleep 1;
    ok 1, 'make sure plans work';
}

1;
