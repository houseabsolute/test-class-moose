package Test::Class::Moose::Reporting::Method;

use Moose;
use Carp;
use namespace::autoclean;
with qw(
  Test::Class::Moose::Reporting::Role::Reporting
);

our $VERSION = 0.02;

has 'num_tests' => (
    is  => 'rw',
    isa => 'Int',
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Test::Class::Moose::Reporting::Method - Reporting on test methods

=head1 VERSION

0.02

=head1 DESCRIPTION

Should be considered experimental and B<read only>.

=head1 IMPLEMENTS

C<Test::Class::Moose::Reporting::Role::Reporting>.

=head1 ATTRIBUTES

=head2 C<num_tests>

    my $num_tests = $method->num_tests;

The number of tests run for this test method.
