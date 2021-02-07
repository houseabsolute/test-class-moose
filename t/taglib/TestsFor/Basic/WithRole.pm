package TestsFor::Basic::WithRole;

use strict;
use warnings;
use namespace::autoclean;

use Test::Class::Moose;

with qw/TestsFor::Basic::Role/;

sub test_in_withrole {
    pass 'Got here';
}

1;
