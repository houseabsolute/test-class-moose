package Test::Class::Moose::Report::Class;

# ABSTRACT: Reporting on test classes

use 5.10.0;

our $VERSION = '0.86';

use Moose;
use Carp;
use namespace::autoclean;

with qw(
  Test::Class::Moose::Role::Reporting
);

has test_instances => (
    is      => 'ro',
    traits  => ['Array'],
    isa     => 'ArrayRef[Test::Class::Moose::Report::Instance]',
    default => sub { [] },
    handles => {
        all_test_instances => 'elements',
        add_test_instance  => 'push',
        num_test_instances => 'count',
    },
);

sub current_instance {
    my $self = shift;
    return $self->test_instances->[-1];
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 DESCRIPTION

Should be considered experimental and B<read only>.

=head1 IMPLEMENTS

L<Test::Class::Moose::Role::Reporting>.

=head1 ATTRIBUTES

See L<Test::Class::Moose::Role::Reporting> for additional attributes.

=head2 C<all_test_instances>

Returns an array of L<Test::Class::Moose::Report::Instance> objects.

=head2 C<current_instance>

Returns the current (really, most recent)
L<Test::Class::Moose::Report::Instance> object that is being run.
