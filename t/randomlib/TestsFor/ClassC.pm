package ClassC;

use strict;
use warnings;
use namespace::autoclean;

use Test::Class::Moose;

sub test_c {
    ok( 1, 'package C' );
}

1;
