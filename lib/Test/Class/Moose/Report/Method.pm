package Test::Class::Moose::Report::Method;

# ABSTRACT: Reporting on test methods

use Moose;
use Carp;
use namespace::autoclean;
use Test::Class::Moose::AttributeRegistry;

with qw(
  Test::Class::Moose::Role::Reporting
);

has 'instance_report' => (
    is       => 'ro',
    isa      => 'Test::Class::Moose::Report::Instance',
    required => 1,
    weak_ref => 1,
);

has 'num_tests_run' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

sub tests_run {
    carp "tests_run() deprecated as of version 0.07. Use num_tests_run().";
    goto &num_tests_run;
}

has 'tests_planned' => (
    is        => 'rw',
    isa       => 'Int',
    predicate => 'has_plan',
);

sub plan {
    my ( $self, $integer ) = @_;
    $self->tests_planned( ( $self->tests_planned || 0 ) + $integer );
}

sub add_to_plan {
    my ( $self, $integer ) = @_;
    carp("add_to_plan() is deprecated. You can now call plan() multiple times");
    return $self->plan($integer);
}

sub has_tag {
    my ( $self, $tag ) = @_;
    croak("has_tag(\$tag) requires a tag name") unless defined $tag;
    my $instance_report = $self->instance_report->name;
    my $method          = $self->name;
    return Test::Class::Moose::AttributeRegistry->method_has_tag( $instance_report, $method, $tag );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 DESCRIPTION

Should be considered experimental and B<read only>.

=head1 IMPLEMENTS

L<Test::Class::Moose::Role::Reporting>.

=head1 ATTRIBUTES

=head2 C<instance_report>

The C<Test::Class::Moose::Report::Instance> for this method.

=head2 C<num_tests_run>

    my $tests_run = $method->num_tests_run;

The number of tests run for this test method.

=head2 C<tests_planned>

    my $tests_planned = $method->tests_planned;

The number of tests planned for this test method. If a plan has not been
explicitly set with C<$report->test_plan>, then this number will always be
equal to the number of tests run.

=head1 C<has_tag>

    my $method = $test->test_report->current_method;
    if ( $method->has_tag('db') ) {
        $test->load_database_fixtures;
    }

Returns true if the current test method has the tag in question.
