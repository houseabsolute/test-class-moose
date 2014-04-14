package TestsFor::Sequential;

use Test::Class::Moose;

sub test_sequential_first : Tags(noparallel) {
    my $test = shift;
    ok 1;
}

sub test_sequential_second {
    my $test = shift;
    ok 1;
}

1
