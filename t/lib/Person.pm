package Person;

use strict;
use warnings;
use namespace::autoclean;

use Moose;

has [ 'first_name', 'last_name' ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub full_name {
    my $self = shift;
    return join q{ } => $self->first_name, $self->last_name;
}

__PACKAGE__->meta->make_immutable;

1;
