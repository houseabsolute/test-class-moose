package Test::Class::Moose::Reporting;

use 5.10.0;
use Moose;
use namespace::autoclean;

our $VERSION = 0.05;

has 'num_test_methods' => (
    is      => 'rw',
    isa     => 'Int',
    writer  => 'set_num_test_methods',
    default => 0,
);

has 'num_tests' => (
    is      => 'rw',
    isa     => 'Int',
    writer  => 'set_num_tests',
    default => 0,
);

# see Moose::Meta::Attribute::Native::Trait::Array
has test_classes => (
    is     => 'ro',
    traits => ['Array'],
    isa    => 'ArrayRef[Test::Class::Moose::Reporting::Class]',
    default => sub { [] },
    handles => {
        all_test_classes => 'elements',
        add_test_class   => 'push',
        num_test_classes => 'count',
    },
);

sub inc_test_methods {
    my ( $self, $test_methods ) = @_;
    $test_methods //= 1;
    $self->set_num_test_methods( $self->num_test_methods + $test_methods );
}

sub inc_tests {
    my ( $self, $tests ) = @_;
    $tests //= 1;
    $self->set_num_tests( $self->num_tests + $tests );
}

sub current_class {
    my $self = shift;
    return $self->test_classes->[-1];
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Test::Class::Moose::Reporting - Test information for Test::Class::Moose

=head1 VERSION

0.05

=head1 SYNOPSIS

 my $statistics = Test::Class::Moose::Reporting->new;

=head1 DESCRIPTION

For internal use only (maybe I'll expose it later). Not guaranteed to be
stable.

=head1 ATTRIBUTES

=head2 * C<num_test_classes>

Integer. The number of test classes run.

=head2 * C<num_test_methods>

Integer. The number of test methods run.

=head2 C<num_tests>

Integer. The number of tests run.

=head1 METHODS

=head2 C<inc_test_classes>

    $statistics->inc_test_classes;        # increments by 1
    $statistics->inc_test_classes($x);    # increments by $x

=head2 C<inc_test_methods>

    $statistics->inc_test_methods;        # increments by 1
    $statistics->inc_test_methods($x);    # increments by $x

=head2 C<inc_tests>

    $statistics->inc_tests;        # increments by 1
    $statistics->inc_tests($x);    # increments by $x

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-class-moose at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Class-Moose>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Class::Moose

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Class-Moose>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Class-Moose>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Class-Moose>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Class-Moose/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Curtis "Ovid" Poe.

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
