package TAP::Stream::Role::ToString;

# ABSTRACT: Experimental role for TAP stream builder

use Moose::Role;

requires qw(
    tap_to_string
);
has 'name' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Unnamed TAP stream',
);

1;

__END__

=head1 DESCRIPTION

See L<TAP::Stream>.

B<FOR INTERNAL USE ONLY>
