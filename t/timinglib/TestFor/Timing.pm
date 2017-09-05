package TestFor::Timing;

use strict;
use warnings;

use Test::Class::Moose;

sub test_timing {
    sleep 2;
    ok( 1, 'slept for 2 seconds' );
}

1;
