package TestsFor::Beta;

use Test::Class::Moose;

sub test_beta_first {
    my $test = shift;
    ok 1;
    sleep 1;
    ok 2;
    sleep 1;
}

sub test_second {
    my $test = shift;
    ok 1;
    sleep 1;
    ok 2;
    sleep 1;
}

1
