package TAP::Stream::Text;

# ABSTRACT: Experimental TAP stream builder for parallel tests

use Moose;
use namespace::autoclean;
with qw(TAP::Stream::Role::ToString);

has 'text' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub tap_to_string { shift->text }

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 DESCRIPTION

See L<TAP::Stream>.

B<FOR INTERNAL USE ONLY>
