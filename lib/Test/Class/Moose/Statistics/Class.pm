package Test::Class::Moose::Statistics::Class;

use Moose;
use Carp;
use namespace::autoclean;

our $VERSION = 0.02;

with qw(
  Test::Class::Moose::Statistics::Role::Statistics
);

has test_methods => (
    is      => 'rw',
    traits  => ['Array'],
    isa     => 'ArrayRef[Test::Class::Moose::Statistics::Method]',
    default => sub { [] },
    handles => {
        all_test_methods => 'elements',
        add_test_method  => 'push',
        num_test_methods => 'count',
    },
);

__PACKAGE__->meta->make_immutable;

1;


__END__

=head1 NAME

Test::Class::Moose::Statistics::class - Statistics on test classes

=head1 VERSION

0.02

=head1 DESCRIPTION

Should be considered experimental and B<read only>.

=head1 IMPLEMENTS

C<Test::Class::Moose::Statistics::Role::Statistics>.

=head1 ATTRIBUTES

=head2 C<test_methods>

Returns an array reference of L<Test::Class::Moose::Statistics::Method>
objects.
