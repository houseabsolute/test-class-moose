package Test::Class::Moose::Executor::Sequential;

# ABSTRACT: Execute tests sequentially

use 5.10.0;

our $VERSION = '0.70';

use Moose 2.0000;
use Carp;
use namespace::autoclean;
with 'Test::Class::Moose::Role::Executor';

__PACKAGE__->meta->make_immutable;

1;

=for Pod::Coverage Tags Tests runtests
