package Test::Class::Moose::Report::Method;

# ABSTRACT: Reporting on test methods

use Moose;
use Carp;
use namespace::autoclean;
with qw(
  Test::Class::Moose::Role::Reporting
);

has 'tests_run' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has 'tests_planned' => (
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
    $self->tests_planned($integer);
}

sub add_to_plan {
    my ( $self, $integer ) = @_;

    unless ( $self->has_plan ) {
        my $name = $self->name;
        croak("You cannot add to a non-existent plan in method $name");
    }
    $self->tests_planned( $self->tests_planned + $integer );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 DESCRIPTION

Should be considered experimental and B<read only>.

=head1 IMPLEMENTS

L<Test::Class::Moose::Role::Reporting>.

=head1 ATTRIBUTES

=head2 C<tests_run>

    my $tests_run = $method->tests_run;

The number of tests run for this test method.

=head2 C<tests_planned>

    my $tests_planned = $method->tests_planned;

The number of tests planned for this test method. If a plan has not been
explicitly set with C<$report->test_plan>, then this number will always be
equal to the number of tests run.
