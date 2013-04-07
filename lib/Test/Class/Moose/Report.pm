package Test::Class::Moose::Report;

# ABSTRACT: Test information for Test::Class::Moose

use 5.10.0;
use Carp;
use Moose;
use namespace::autoclean;

has 'num_test_methods' => (
    is      => 'rw',
    isa     => 'Int',
    writer  => 'set_num_test_methods',
    default => 0,
);

has 'num_tests_run' => (
    is      => 'rw',
    isa     => 'Int',
    writer  => 'set_tests_run',
    default => 0,
);

sub tests_run {
    carp "tests_run() deprecated as of version 0.07. Use num_tests_run().";
    goto &num_tests_run;
}

# see Moose::Meta::Attribute::Native::Trait::Array
has test_classes => (
    is      => 'ro',
    traits  => ['Array'],
    isa     => 'ArrayRef[Test::Class::Moose::Report::Class]',
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
    $self->set_tests_run( $self->num_tests_run + $tests );
}

sub current_class {
    my $self = shift;
    return $self->test_classes->[-1];
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 SYNOPSIS

 my $report = Test::Class::Moose->new->runtests->test_report;

=head1 DESCRIPTION

When working with larger test suites, it's useful to have full reporting
information avaiable about the test suite. The reporting features of
L<Test::Class::Moose> allow you to report on the number of test classes and
methods run (and number of tests), along with timing information to help you
track down which tests are running slowly. You can even run tests on your
report information:

    #!/usr/bin/env perl
    use lib 'lib';
    use Test::Most;
    use Test::Class::Moose::Load qw(t/lib);
    my $test_suite = Test::Class::Moose->new;

    subtest 'run the test suite' => sub {
        $test_suite->runtests;
    };
    my $report = $test_suite->test_report;

    foreach my $class ( $report->all_test_classes ) {
        my $class_name = $class->name;
        ok !$class->is_skipped, "$class_name was not skipped";

        subtest "$class_name methods" => sub {
            foreach my $method ( $class->all_test_methods ) {
                my $method_name = $method->name;
                ok !$method->is_skipped, "$method_name was not skipped";
                cmp_ok $method->num_tests, '>', 0,
                  '... and some tests should have been run';
                diag "Run time for $method_name: ".$method->time->duration;
            }
        };
        my $time   = $class->time;
        diag "Run time for $class_name: ".$class->time->duration;

        my $real   = $time->real;
        my $user   = $time->user;
        my $system = $time->system;
        # do with these as you will
    }
    diag "Number of test classes: " . $report->num_test_classes;
    diag "Number of test methods: " . $report->num_test_methods;
    diag "Number of tests:        " . $report->num_tests;

    done_testing;


Reporting is currently in alpha. The interface is not guaranteed to be stable.

=head2 The Report

 my $report = Test::Class::Moose->new->runtests->test_report;

After the test suite is run, you can call the C<test_report> method to get the
report. The test report is a L<Test::Class::Moose::Report> object. This object
provides the following methods:

=head3 C<test_classes>

Returns an array reference of L<Test::Class::Moose::Report::Class> instances.

=head3 C<all_test_classes>

Returns an array of L<Test::Class::Moose::Report::Class> instances.

=head3 C<num_test_classes>

Integer. The number of test classes run.

=head3 C<num_test_methods>

Integer. The number of test methods run.

=head3 C<num_tests_run>

Integer. The number of tests run.

=head2 Test Report Class

Each L<Test::Class::Moose::Report::Class> instance provides the following
methods:

=head3 C<test_methods>

Returns an array reference of L<Test::Class::Moose::Report::Method>
objects.

=head3 C<all_test_methods>

Returns an array of L<Test::Class::Moose::Report::Method> objects.

=head3 C<error>

If this class could not be run, returns a string explaining the error.

=head3 C<has_error>

Returns a boolean indicating whether or not the class has an error.

=head2 C<name>

The name of the test class.

=head2 C<notes>

A hashref. The end user may use this to store anything desired.

=head2 C<skipped>

If the class or method is skipped, this will return the skip message.

=head2 C<is_skipped>

Returns true if the class or method is skipped.

=head2 C<time>

Returns a L<Test::Class::Moose::Report::Time> object. This object
represents the duration of this class.


Each L<Test::Class::Moose::Report::Class> instance provides the
following methods:

=head3 C<test_methods>

Returns an array reference of L<Test::Class::Moose::Report::Method>
objects.

=head3 C<all_test_methods>

Returns an array of L<Test::Class::Moose::Report::Method> objects.

=head3 C<error>

If this class could not be run, returns a string explaining the error.

=head3 C<has_error>

Returns a boolean indicating whether or not the class has an error.

=head2 C<name>

The name of the test class.

=head2 C<notes>

A hashref. The end user may use this to store anything desired.

=head2 C<skipped>

If the class or method is skipped, this will return the skip message.

=head2 C<is_skipped>

Returns true if the class or method is skipped.

=head2 C<time>

Returns a L<Test::Class::Moose::Report::Time> object. This object
represents the duration of this class.

=head

=head1 METHODS

The following methods are for internal use only. They are included here for
those who might want to hack on L<Test::Class::Moose>.

=head2 C<inc_test_classes>

    $statistics->inc_test_classes;        # increments by 1
    $statistics->inc_test_classes($x);    # increments by $x

=head2 C<inc_test_methods>

    $statistics->inc_test_methods;        # increments by 1
    $statistics->inc_test_methods($x);    # increments by $x

=head2 C<inc_tests>

    $statistics->inc_tests;        # increments by 1
    $statistics->inc_tests($x);    # increments by $x

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

=cut

1;