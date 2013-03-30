package Test::Class::Moose::Role::Reporting;

# ABSTRACT: Reporting gathering role

use Moose::Role;
use Benchmark qw(timediff timestr :hireswallclock);
use Test::Class::Moose::Report::Time;

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
    trigger => sub {
        my $self = shift;
        my $time = Test::Class::Moose::Report::Time->new(
            timediff( $self->end_benchmark, $self->start_benchmark ) 
        );
        $self->time($time);
    },
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

has 'time' => (
    is  => 'rw',
    isa => 'Test::Class::Moose::Report::Time',
);

1;

__END__

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

=head2 C<time>

Returns a L<Test::Class::Moose::Report::Time> object. This object
represents the duration of this class or method.
