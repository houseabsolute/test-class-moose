package Test::Class::Moose::Role::Reporting;

use Moose::Role;
use Benchmark qw(timediff timestr :hireswallclock);

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'start_benchmark' => (
    is  => 'rw',
    isa => 'Benchmark',
);

has 'end_benchmark' => (
    is  => 'rw',
    isa => 'Benchmark',
);

has 'notes' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has skipped => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'is_skipped',
);


sub duration_ref {
    my $self = shift;
    foreach my $method ( qw(start_benchmark end_benchmark) ) {
        next if defined $self->$method;
        croak("Cannot fetch duration(). $method not set");
    }
    return timediff( $self->end_benchmark, $self->start_benchmark );
}

sub duration {
    my $self = shift;
    return timestr( $self->duration_ref );
}

1;

__END__

=head1 NAME

Test::Class::Moose::Role::Reporting - Reporting gathering role

=head1 DESCRIPTION

Note that everything in here is experimental and subject to change.

=head1 REQUIRES

None.

=head1 PROVIDED

=head1 ATTRIBUTES

=head2 C<name>

The "name" of the statistic. For a class, this should be the class name. For a
method, it should be the method name.

=head2 C<start_benchmark>

The starting C<Benchmark> object.

=head2 C<end_benchmark>

The ending C<Benchmark> object.

=head2 C<notes>

A hashref. The end user may use this to store anything desired.

=head2 C<skipped>

If the class or method is skipped, this will return the skip message.

=head2 C<is_skipped>

Returns true if the class or method is skipped.

=head1 METHODS

=head2 C<duration_ref>

Returns the C<Benchmark> duration array reference. Do with it as you will.

=head2 C<duration>

Returns the Benchmark::timestr() of the C<duration_ref>.
