package Test::Class::Moose::Reporting::Class;

use Moose;
use Carp;
use namespace::autoclean;

our $VERSION = 0.02;

with qw(
  Test::Class::Moose::Reporting::Role::Reporting
);

has test_methods => (
    is      => 'rw',
    traits  => ['Array'],
    isa     => 'ArrayRef[Test::Class::Moose::Reporting::Method]',
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

Test::Class::Moose::Reporting::class - Reporting on test classes

=head1 VERSION

0.02

=head1 DESCRIPTION

Should be considered experimental and B<read only>.

=head1 IMPLEMENTS

C<Test::Class::Moose::Reporting::Role::Reporting>.

=head1 ATTRIBUTES

=head2 C<test_methods>

Returns an array reference of L<Test::Class::Moose::Reporting::Method>
objects.
