package Test::Class::Moose::Role::Timing;

# ABSTRACT: Report timing role

use Moose::Role;
use Benchmark qw(timediff timestr :hireswallclock);
use Test::Class::Moose::Report::Time;

# this seems like some serious abuse of attributes. Plus, time() is only set
# as a side-effect of _end_benchmark(). I should rethink this. It's hidden
# from the outside world, but still ...
has '_start_benchmark' => (
    is            => 'rw',
    isa           => 'Benchmark',
    lazy          => 1,
    default       => sub { Benchmark->new },
    documentation => 'Trusted method for Test::Class::Moose',
);

has '_end_benchmark' => (
    is      => 'rw',
    isa     => 'Benchmark',
    lazy    => 1,
    default => sub {
        my $self      = shift;
        my $benchmark = Benchmark->new;
        my $time      = Test::Class::Moose::Report::Time->new(
            timediff( $benchmark, $self->_start_benchmark ) );
        $self->time($time);
        return $benchmark;
    },
    documentation => 'Trusted method for Test::Class::Moose',
);

has 'time' => (
    is      => 'rw',
    isa     => 'Test::Class::Moose::Report::Time',
    default => sub {

        # return a "zero" if no time is set
        my $self      = shift;
        my $benchmark = Benchmark->new;
        return Test::Class::Moose::Report::Time->new(
            timediff( $benchmark, $benchmark ) );
    },
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
represents the duration of this class or method. The duration may be "0" if
it's an abstract class with no tests run.
