package Test::Class::Moose::Reporting::Method;

# ABSTRACT: Reporting on test methods

use Moose;
use Carp;
use namespace::autoclean;
with qw(
  Test::Class::Moose::Role::Reporting
);

has 'num_tests' => (
    is  => 'rw',
    isa => 'Int',
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 DESCRIPTION

Should be considered experimental and B<read only>.

=head1 IMPLEMENTS

C<Test::Class::Moose::Role::Reporting>.

=head1 ATTRIBUTES

=head2 C<num_tests>

    my $num_tests = $method->num_tests;

The number of tests run for this test method.
