package TestsFor::Beta;

use Test::Class::Moose extends => 'MyParallelTests';

sub test_beta_first {
    my ( $test, $report ) = @_;
    ok 1;
    sleep 1;
    ok 2;
    sleep 1;
}

sub test_second {
    my ( $test, $report ) = @_;
    ok 1;
    sleep 1;
    ok 2;
    sleep 1;
}

1
