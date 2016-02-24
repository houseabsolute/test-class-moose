package Test::Class::Moose::Executor::Sequential;

# ABSTRACT: Execute tests sequentially

use 5.10.0;

our $VERSION = '0.70';

use Moose 2.0000;
use Carp;
use namespace::autoclean;
with 'Test::Class::Moose::Role::Executor';

use Test::Class::Moose::Report::Class;
use Test2::API qw( context_do );
use Test2::Tools::AsyncSubtest qw( subtest_start subtest_run subtest_finish );
use Try::Tiny;

__PACKAGE__->meta->make_immutable;

1;

=for Pod::Coverage Tags Tests runtests
