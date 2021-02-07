package ClassB;

use strict;
use warnings;
use namespace::autoclean;

use Test::Class::Moose;

sub test_b {
    ok( 1, 'package B' );
}

1;
