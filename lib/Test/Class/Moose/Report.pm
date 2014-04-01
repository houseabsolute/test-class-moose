package Test::Class::Moose::Report;

# ABSTRACT: Test information for Test::Class::Moose

use 5.10.0;
use Carp;
use Moose;
use namespace::autoclean;
with 'Test::Class::Moose::Role::Timing';

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
has test_instances => (
    is      => 'ro',
    traits  => ['Array'],
    isa     => 'ArrayRef[Test::Class::Moose::Report::Instance]',
    default => sub { [] },
    handles => {
        all_test_instances => 'elements',
        add_test_instance  => 'push',
        num_test_instances => 'count',
    },
);

sub _inc_test_methods {
    my ( $self, $test_methods ) = @_;
    $test_methods //= 1;
    $self->set_num_test_methods( $self->num_test_methods + $test_methods );
}

sub _inc_tests {
    my ( $self, $tests ) = @_;
    $tests //= 1;
    $self->set_tests_run( $self->num_tests_run + $tests );
}

sub current_class {
    my $self = shift;
    return $self->test_instances->[-1];
}

sub current_method {
    my $self = shift;
    my $current_class = $self->current_class or return;
    return $current_class->current_method;
}

sub plan {
    my ( $self, $plan ) = @_;
    my $current_method = $self->current_method
        or croak("You tried to plan but we don't have a test method yet!");
    $current_method->plan($plan);
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 SYNOPSIS

 my $report = Test::Class::Moose->new->runtests->test_report;

=head1 DESCRIPTION

When working with larger test suites, it's useful to have full reporting
information avaiable about the test suite. The reporting features of
L<Test::Class::Moose> allow you to report on the number of test class instances and
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
    my $duration = $report->time->duration;
    diag "Test suite run time: $duration";

    foreach my $class ( $report->all_test_instances ) {
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
    diag "Number of test instances: " . $report->num_test_instances;
    diag "Number of test methods: "   . $report->num_test_methods;
    diag "Number of tests:        "   . $report->num_tests;

    done_testing;


Reporting is currently in alpha. The interface is not guaranteed to be stable.

=head2 The Report

 my $report = Test::Class::Moose->new->runtests->test_report;

Or:

 my $test_suite = Test::Class::Moose->new;
 $test_suite->runtests;
 my $report = $test_suite->test_report;

After the test suite is run, you can call the C<test_report> method to get the
report. The test report is a L<Test::Class::Moose::Report> object. This object
provides the following methods:

=head3 C<test_instances>

Returns an array reference of L<Test::Class::Moose::Report::Instance> instances.

=head3 C<all_test_instances>

Returns an array of L<Test::Class::Moose::Report::Instance> instances.

=head3 C<num_test_instances>

Integer. The number of test instances run.

=head3 C<num_test_methods>

Integer. The number of test methods run.

=head3 C<num_tests_run>

Integer. The number of tests run.

=head3 C<time>

Returns a L<Test::Class::Moose::Report::Time> object. This object
represents the duration of the entire test suite.

=head2 Test Report for Instances

Each L<Test::Class::Moose::Report::Instance> instance provides the following
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

=head3 C<name>

The name of the test class.

=head3 C<notes>

A hashref. The end user may use this to store anything desired.

=head3 C<skipped>

If the class or method is skipped, this will return the skip message.

=head3 C<is_skipped>

Returns true if the class or method is skipped.

=head3 C<time>

Returns a L<Test::Class::Moose::Report::Time> object. This object
represents the duration of this class.

=head2 Test Report for Methods

Each L<Test::Class::Moose::Report::Method> instance provides the following
methods:

=head3 C<name>

The "name" of the test method.

=head3 C<notes>

A hashref. The end user may use this to store anything desired.

=head3 C<skipped>

If the class or method is skipped, this will return the skip message.

=head3 C<is_skipped>

Returns true if the class or method is skipped.

=head3 C<time>

Returns a L<Test::Class::Moose::Report::Time> object. This object
represents the duration of this class or method.

=head2 Test Report for Time

Each L<Test::Class::Moose::Report::Time> instance has the following methods:

=head3 C<real>

    my $real = $time->real;

Returns the "real" amount of time the class or method took to run.

=head3 C<user>

    my $user = $time->user;

Returns the "user" amount of time the class or method took to run.

=head3 C<system>

    my $system = $time->system;

Returns the "system" amount of time the class or method took to run.

=head3 C<duration>

Returns the returns a human-readable representation of the time this class or
method took to run. Something like:

  0.00177908 wallclock secs ( 0.00 usr +  0.00 sys =  0.00 CPU)

=head1 TRUSTED METHODS

The following L<Test::Class::Moose::Report> methods are for internal use only
and are called by L<Test::Class::Moose>.  They are included here for those who
might want to hack on L<Test::Class::Moose>.

=head2 C<_inc_test_methods>

    $statistics->_inc_test_methods;        # increments by 1
    $statistics->_inc_test_methods($x);    # increments by $x

=head2 C<_inc_tests>

    $statistics->_inc_tests;        # increments by 1
    $statistics->_inc_tests($x);    # increments by $x

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
