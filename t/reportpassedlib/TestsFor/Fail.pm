package TestsFor::Fail;

use strict;
use warnings;
use namespace::autoclean;

use Test::Class::Moose;

sub test_a_good {
    ok 1;
}

sub test_a_bad {
    ok 0;
}

sub test_b_good {
    ok 1;
}

sub test_b_bad {
    ok 0;
}

1;
