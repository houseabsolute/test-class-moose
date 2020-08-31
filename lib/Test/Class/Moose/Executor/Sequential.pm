package Test::Class::Moose::Executor::Sequential;

# ABSTRACT: Execute tests sequentially

use 5.010000;

our $VERSION = '0.99';

use Moose 2.0000;
use Carp;
use Test2::Tools::Subtest qw( subtest_streamed );
use namespace::autoclean;
with 'Test::Class::Moose::Role::Executor';

sub _run_subtest {
    shift;

    subtest_streamed(@_);
}

__PACKAGE__->meta->make_immutable;

1;

=for Pod::Coverage Tags Tests runtests
