package Test::Class::Moose::Executor::Sequential;

# ABSTRACT: Execute tests sequentially

use strict;
use warnings;
use namespace::autoclean;

use 5.010000;

our $VERSION = '0.99';

use Moose 2.0000;
use Carp;
with 'Test::Class::Moose::Role::Executor';

__PACKAGE__->meta->make_immutable;

1;

=for Pod::Coverage Tags Tests runtests
