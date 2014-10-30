package Test::Class::Moose::Report::Instance;

# ABSTRACT: Reporting on test classes

use Moose;
use Carp;
use namespace::autoclean;

with qw(
  Test::Class::Moose::Role::Reporting
);

has test_methods => (
    is      => 'rw',
    traits  => ['Array'],
    isa     => 'ArrayRef[Test::Class::Moose::Report::Method]',
    default => sub { [] },
    handles => {
        all_test_methods => 'elements',
        add_test_method  => 'push',
        num_test_methods => 'count',
    },
);

has 'error' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_error',
);

sub current_method {
    my $self = shift;
    return $self->test_methods->[-1];
}

__PACKAGE__->meta->make_immutable;

1;


__END__

=head1 DESCRIPTION

Should be considered experimental and B<read only>.

=head1 IMPLEMENTS

L<Test::Class::Moose::Role::Reporting>.

=head1 ATTRIBUTES

=head2 C<test_methods>

Returns an array reference of L<Test::Class::Moose::Report::Method>
objects.

=head2 C<all_test_methods>

Returns an array of L<Test::Class::Moose::Report::Method> objects.

=head2 C<error>

If this class could not be run, returns a string explaining the error.

=head2 C<has_error>

Returns a boolean indicating whether or not the class has an error.
