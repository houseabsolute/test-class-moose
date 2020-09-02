package Test::Class::Moose::Executor::Sequential;

# ABSTRACT: Execute tests sequentially

use 5.010000;

our $VERSION = '0.99';

use Moose 2.0000;
use Carp;
use Test2::API qw( context run_subtest );
use namespace::autoclean;
with 'Test::Class::Moose::Role::Executor';

sub _run_subtest {
    shift;
    my $name   = shift;
    my $params = shift;
    my $code   = shift;

    my $ctx  = context();
    my $pass = run_subtest(
        $name,
        $code,
        { %{$params}, buffered => 0 },
        @_,
    );
    $ctx->release;

    return $pass;
}

__PACKAGE__->meta->make_immutable;

1;

=for Pod::Coverage Tags Tests runtests
