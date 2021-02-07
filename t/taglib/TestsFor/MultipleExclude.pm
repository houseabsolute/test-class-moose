package TestsFor::MultipleExclude;

use strict;
use warnings;
use namespace::autoclean;

use Test::Class::Moose;

# A regression test for https://rt.cpan.org/Ticket/Display.html?id=87801,
# where we discovered that excluded tags were ANDed together instead of ORed

sub test_87801_1 : Tags( ALL 001 ) {
    ok( 1, 'Test 1' );
}

sub test_87801_2 : Tags( ALL 002 ) {
    ok( 1, 'Test 2' );
}

sub test_87801_3 : Tags( ALL 003 ) {
    ok( 1, 'Test 2' );
}

1;
