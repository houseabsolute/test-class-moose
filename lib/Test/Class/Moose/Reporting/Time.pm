package Test::Class::Moose::Reporting::Time;

# ABSTRACT: Reporting object for timing

use Moose;
use Benchmark qw(timestr :hireswallclock);
use namespace::autoclean;

has 'real'             => ( is => 'ro', isa => 'Num',       required => 1 );
has 'user'             => ( is => 'ro', isa => 'Num',       required => 1 );
has 'system'           => ( is => 'ro', isa => 'Num',       required => 1 );
has '_children_user'   => ( is => 'ro', isa => 'Num',       required => 1 );
has '_children_system' => ( is => 'ro', isa => 'Num',       required => 1 );
has '_iters'           => ( is => 'ro', isa => 'Num',       required => 1 );
has '_timediff'        => ( is => 'ro', isa => 'Benchmark', required => 1 );

around 'BUILDARGS' => sub {
    my ( $orig, $class, $timediff ) = @_;
    my %args;
    @args{
        qw/
          real
          user
          system
          _children_user
          _children_system
          _iters
          /
      }
      = @$timediff;
    $args{_timediff} = $timediff;
    return $class->$orig(%args);
};

sub duration {
    my $self = shift;
    return timestr( $self->_timediff );
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
