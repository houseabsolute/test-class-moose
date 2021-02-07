package ClassA;

use strict;
use warnings;
use namespace::autoclean;

use Test::Class::Moose;

sub test_a {
    ok( 1, 'package A' );
}

1;
