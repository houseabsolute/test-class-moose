use strict;
use warnings;
use Test::Class::Moose::Runner;
use Test::Class::Moose::Load qw(t/lib_with_a+);
Test::Class::Moose::Runner->new->runtests;
