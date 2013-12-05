package TestsFor::Alpha;

use Test::Class::Moose extends => 'MyParallelTests';

sub test_alpha_first {
    my ( $test, $report ) = @_;
    ok 1;
    sleep 1;
    ok 2;
    sleep 1;
}

sub test_second {
    my ( $test, $report ) = @_;
    $report->plan(1);
    sleep 1;
    ok 1, 'make sure plans work';
}

1;
