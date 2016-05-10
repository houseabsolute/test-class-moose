package Test::Class::Moose::Role::Parallel;

# ABSTRACT: Deprecated parallel runner role - see docs for details

use 5.10.0;

our $VERSION = '0.73';

use Moose::Role 2.0000;
use namespace::autoclean;

requires 'runtests';

before runtests => sub {
    warn
      "The Test::Class::Moose::Role::Parallel role is deprecated. Use the new Test::Class::Moose::Runner class instead.";
};

1;

__END__

=head1 DESCRIPTION

This role is now deprecated. To run tests in parallel, use the new
L<Test::Class::Moose::Runner> class:

    use Test::Class::Moose::Runner;

    Test::Class::Moose::Runner->new(
        jobs => 4,
    )->runtests();


=cut
