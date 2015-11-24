package Test::Class::Moose::Role::HasTimeReport;

# ABSTRACT: Report timing role

use Moose::Role;
use Benchmark qw(timediff timestr :hireswallclock);
use Test::Class::Moose::Report::Time;

has '_start_benchmark' => (
    is            => 'ro',
    isa           => 'Benchmark',
    lazy          => 1,
    default       => sub { Benchmark->new },
    predicate     => '_has_start_benchmark',
    documentation => 'Trusted method for Test::Class::Moose',
);

has '_end_benchmark' => (
    is            => 'ro',
    isa           => 'Benchmark',
    lazy          => 1,
    default       => sub { Benchmark->new },
    predicate     => '_has_end_benchmark',
    documentation => 'Trusted method for Test::Class::Moose',
);

has 'time' => (
    is      => 'ro',
    isa     => 'Test::Class::Moose::Report::Time',
    lazy    => 1,
    builder => '_build_time',
);

sub _build_time {
    my $self = shift;

    # If we don't have start & end marked we'll return a report with zero time
    # elapsed.
    unless ( $self->_has_start_benchmark && $self->_has_end_benchmark ) {
        my $benchmark = Benchmark->new;
        return Test::Class::Moose::Report::Time->new(
            timediff( $benchmark, $benchmark ) );
    }

    return Test::Class::Moose::Report::Time->new( timediff =>
          timediff( $self->_end_benchmark, $self->_start_benchmark ) );
}

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
