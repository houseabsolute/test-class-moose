package Test::Class::Moose::Report::Time;

# ABSTRACT: Reporting object for timing

use 5.010000;

our $VERSION = '0.99';

use Moose;
use Benchmark qw(timestr :hireswallclock);
use List::Util qw( max );
use namespace::autoclean;

{
    my @fields = qw( real user system );
    for my $i ( 0 .. $#fields ) {
        has $fields[$i] => (
            is       => 'ro',
            isa      => 'Num',
            lazy     => 1,
            default  => sub { max( $_[0]->_timediff->[$i], 0 ) },
            init_arg => undef,
        );
    }
}

has '_timediff' => (
    is       => 'ro',
    isa      => 'Benchmark',
    required => 1,
    init_arg => 'timediff',
);

sub duration {
    my $self = shift;
    return timestr( $self->_timediff );
}

sub as_hashref {
    my $self = shift;
    return { map { $_ => $self->$_ } qw( real user system ) };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 DESCRIPTION

Note that everything in here is experimental and subject to change.

All times are in seconds.

=head1 ATTRIBUTES

=head2 C<real>

    my $real = $time->real;

Returns the "real" amount of time the class or method took to run.

=head2 C<user>

    my $user = $time->user;

Returns the "user" amount of time the class or method took to run.

=head2 C<system>

    my $system = $time->system;

Returns the "system" amount of time the class or method took to run.

=head1 METHODS

=head2 C<duration>

Returns the returns a human-readable representation of the time this class or
method took to run. Something like:

  0.00177908 wallclock secs ( 0.00 usr +  0.00 sys =  0.00 CPU)

=head2 C<as_hashref>

Returns the C<real>, C<user>, and C<system> time values in a hashref.
