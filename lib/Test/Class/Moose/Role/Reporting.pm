package Test::Class::Moose::Role::Reporting;

# ABSTRACT: Reporting gathering role

use strict;
use warnings;
use namespace::autoclean;

use 5.10.0;

our $VERSION = '0.73';

use Moose::Role;
with 'Test::Class::Moose::Role::HasTimeReport';

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'notes' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'skipped' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'is_skipped',
);

has 'passed' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

1;

__END__

=head1 DESCRIPTION

Note that everything in here is experimental and subject to change.

=head1 IMPLEMENTS

L<Test::Class::Moose::Role::HasTimeReport>.

=head1 REQUIRES

None.

=head1 PROVIDED

=head1 ATTRIBUTES

=head2 C<name>

The "name" of the statistic. For a class, this should be the class name. For a
method, it should be the method name.

=head2 C<notes>

A hashref. The end user may use this to store anything desired.

=head2 C<skipped>

If the class or method is skipped, this will return the skip message.

=head2 C<is_skipped>

Returns true if the class or method is skipped.

=head2 C<passed>

Returns true if the class or method passed.

=head2 C<time>

(From L<Test::Class::Moose::Role::HasTimeReport>)

Returns a L<Test::Class::Moose::Report::Time> object. This object
represents the duration of this class or method.
