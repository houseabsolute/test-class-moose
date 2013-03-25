package Test::Class::Moose::Reporting::Method;

# ABSTRACT: Reporting on test methods

use Moose;
use Carp;
use namespace::autoclean;
with qw(
  Test::Class::Moose::Role::Reporting
);

has 'num_tests' => (
    is        => 'rw',
    isa       => 'Int',
    predicate => 'has_plan',
);

sub plan {
    my ( $self, $integer ) = @_;
    if ( $self->has_plan ) {
        my $name = $self->name;
        croak("You tried to plan twice in test method '$name'");
    }
    $self->num_tests($integer);
}

sub add_to_plan {
    my ( $self, $integer ) = @_;

    unless ( $self->has_plan ) {
        my $name = $self->name;
        croak("You cannot add to a non-existent plan in method $name");
    }
    $self->num_tests( $self->num_tests + $integer );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 DESCRIPTION

Should be considered experimental and B<read only>.

=head1 IMPLEMENTS

C<Test::Class::Moose::Role::Reporting>.

=head1 ATTRIBUTES

=head2 C<num_tests>

    my $num_tests = $method->num_tests;

The number of tests run for this test method.
