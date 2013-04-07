package Test::Class::Moose::Role::Timing;

# ABSTRACT: Report timing role

use Moose::Role;
use Benchmark qw(timediff timestr :hireswallclock);
use Test::Class::Moose::Report::Time;

has '_start_benchmark' => (
    is            => 'rw',
    isa           => 'Benchmark',
    documentation => 'Trusted method for Test::Class::Moose',
);

has '_end_benchmark' => (
    is      => 'rw',
    isa     => 'Benchmark',
    trigger => sub {
        my $self = shift;
        my $time = Test::Class::Moose::Report::Time->new(
            timediff( $self->_end_benchmark, $self->_start_benchmark ) );
        $self->time($time);
    },
    documentation => 'Trusted method for Test::Class::Moose',
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

=head2 C<time>

Returns a L<Test::Class::Moose::Report::Time> object. This object
represents the duration of this class or method.
