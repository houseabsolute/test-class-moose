package PersonTest;

use Moose;

has [ 'first_name', 'last_name' ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub full_name {
    my $self = shift;
    return join ' ' => $self->first_name, $self->last_name;
}

1;
