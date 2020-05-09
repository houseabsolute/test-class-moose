use strict;
use warnings;

use FindBin qw( $Bin );
use Test::Class::Moose::Load "$Bin/lib_with_a+";
use Test::Class::Moose::Runner;

Test::Class::Moose::Runner->new->runtests;
