package Test::Class::Moose::Report;

# ABSTRACT: Test information for Test::Class::Moose

use 5.10.0;

our $VERSION = '0.63';

use Carp;
use Moose;
use namespace::autoclean;
with 'Test::Class::Moose::Role::HasTimeReport';

use List::Util qw( sum );

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

has 'is_parallel' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has test_classes => (
    is      => 'ro',
    traits  => ['Array'],
    isa     => 'ArrayRef[Test::Class::Moose::Report::Class]',
    default => sub { [] },
    handles => {
        _all_test_classes => 'elements',
        add_test_class    => 'push',
        num_test_classes  => 'count',
    },
);

sub num_test_instances {
    my $self = shift;
    return sum map { $_->num_test_instances } $self->all_test_classes;
}

sub all_test_classes {
    my $self = shift;
    warn
      "When running tests in parallel we are unable to store test classes\n"
      if $self->is_parallel;
    return $self->_all_test_classes;
}

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
    return $self->test_classes->[-1];
}

sub current_instance {
    my $self = shift;
    my $current_class = $self->current_class or return;
    return $current_class->current_instance;
}

sub current_method {
    my $self = shift;
    my $current_instance = $self->current_instance or return;
    return $current_instance->current_method;
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

=for Pod::Coverage plan

=head1 SYNOPSIS

    use Test::Class::Moose::Runner;

    my $runner = Test::Class::Moose::Runner->new;
    $runner->runtests;
    my $report = $runner->test_report;

=head1 DESCRIPTION

When working with larger test suites, it's useful to have full reporting
information available about the test suite. The reporting features of
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

    foreach my $class (@c) {
        my $class_name = $class->name;
        subtest "report for class:$class_name" => sub {
            ok !$class->is_skipped, "class:$class_name was not skipped";
            ok $class->passed, "class:$class_name passed";

            my @i = $class->all_test_instances;
            is scalar @i, 1, "tested one instance for $class_name";

            foreach my $instance (@i) {
                my $instance_name = $instance->name;
                subtest "report for instance:$instance_name" => sub {
                    ok !$instance->is_skipped,
                      "instance:$instance_name was not skipped";
                    ok $instance->passed, "instance:$instance_name passed";

                    my @methods = $instance->all_test_methods;
                    is_deeply
                      [ sort map { $_->name } @methods ],
                      $expected_methods{$class_name},
                      "instance:$instance_name ran the expected methods";

                    foreach my $method (@methods) {
                        my $method_name = $method->name;
                        subtest "report for method:$method_name" => sub {
                            ok !$method->is_skipped,
                              "$method_name was not skipped";
                            cmp_ok $method->num_tests_run, '>', 0,
                              '... and some tests should have been run';
                            _test_report_time($method);
                        };
                    }
                };
            }
        };
    }

Reporting is currently in alpha. The interface is not guaranteed to be stable.

=head1 METHODS

The top level report object for the whole test suite is returned from the
L<Test::Class::Moose::Runner> object's C<test_report> method.

This object provides the following methods:

=head2 C<all_test_classes>

Returns an array of L<Test::Class::Moose::Report::Class> objects.

=head2 C<num_test_classes>

Integer. The number of test classes run.

=head2 C<num_test_instances>

Integer. The number of test instances run.

=head2 C<num_test_methods>

Integer. The number of test methods that the runner tried to run.

=head2 C<num_tests_run>

Integer. The number of tests run.

=head2 C<current_class>

Returns the L<Test::Class::Moose::Report::Class> for the test class currently
being run, if it exists. This may return C<undef>.

=head2 C<current_instance>

Returns the L<Test::Class::Moose::Report::Instance> for the test class
instance currently being run, if it exists. This may return C<undef>.

=head2 C<current_method>

Returns the L<Test::Class::Moose::Report::Method> for the test method
currently being run, if one exists. This may return C<undef>.

=head2 C<time>

Returns a L<Test::Class::Moose::Report::Time> object. This object
represents the duration of the entire test suite.

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
