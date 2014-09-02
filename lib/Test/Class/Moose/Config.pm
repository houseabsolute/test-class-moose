package Test::Class::Moose::Config;

# ABSTRACT: Configuration information for Test::Class::Moose

use 5.10.0;
use Moose;
use Moose::Util::TypeConstraints;
use TAP::Formatter::Color;
use namespace::autoclean;

subtype 'ArrayRefOfStrings', as 'Maybe[ArrayRef[Str]]';

coerce 'ArrayRefOfStrings', from 'Str', via { defined($_) ? [$_] : undef };

has 'show_timing' => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        if ( $_[0]->use_environment and $ENV{HARNESS_IS_VERBOSE} ) {
            return 1;
        }
        return;
    },
);

has 'builder' => (
    is      => 'ro',
    isa     => 'Test::Builder',
    default => sub {
        Test::Builder->new;
    },
);

has 'statistics' => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        if ( $_[0]->use_environment and $ENV{HARNESS_IS_VERBOSE} ) {
            return 1;
        }
        return;
    },
);

has 'use_environment' => (
    is  => 'ro',
    isa => 'Bool',
);

has 'test_class' => (
    is  => 'rw',
    isa => 'Str',
);

has 'randomize' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'include' => (
    is  => 'ro',
    isa => 'Regexp',
);

has 'exclude' => (
    is  => 'ro',
    isa => 'Regexp',
);

has 'include_tags' => (
    is      => 'ro',
    isa     => 'ArrayRefOfStrings',
    coerce  => 1,
    clearer => 'clear_include_tags',
);

has 'exclude_tags' => (
    is      => 'ro',
    isa     => 'ArrayRefOfStrings',
    coerce  => 1,
    clearer => 'clear_exclude_tags',
);

has 'test_classes' => (
    is     => 'ro',
    isa    => 'ArrayRefOfStrings',
    coerce => 1,
);

sub args {
    my $self = shift;

    return {
        map { defined $self->$_ ? ( $_ => $self->$_ ) : () }
        map { $_->name } $self->meta->get_all_attributes
    };
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 SYNOPSIS

 my $tc_config = Test::Class::Moose::Config->new({
     show_timing => 1,
     builder     => Test::Builder->new,
     statistics  => 1,
     randomize   => 0,
 });
 my $test_suite = Test::Class::Moose->new($tc_config);

=head1 DESCRIPTION

For internal use only (maybe I'll expose it later). Not guaranteed to be
stable.

This class defines many of the attributes for L<Test::Class::Moose>. They're
kept here to minimize namespace pollution in L<Test::Class::Moose>.

=head1 ATTRIBUTES

=head2 * C<show_timing>

Boolean. Will display verbose information on the amount of time it takes each
test class/test method to run.

=head2 * C<statistics>

Boolean. Will display number of classes, test methods and tests run.

=head2 * C<use_environment>

Boolean.  Sets show_timing and statistics to true if your test harness is running verbosely, false otherwise.

=head2 C<test_classes>

Takes a class name or an array reference of class names. If it is present, the
C<test_classes> method will only return these classes. This is very useful if
you wish to run an individual class as a test:

    Test::Class::Moose->new(
        test_classes => $ENV{TEST_CLASS}, # ignored if undef
    )->runtests;

=head2 C<include_tags>

Array ref of strings matching method tags (a single string is also ok). If
present, only test methods whose tags match C<include_tags> or whose tags
don't match C<exclude_tags> will be included. B<However>, they must still
start with C<test_>.

For example:

 my $test_suite = Test::Class::Moose->new({
     include_tags => [qw/api database/],
 });

The above constructor will only run tests tagged with C<api> or C<database>.

=head2 C<exclude_tags>

The same as C<include_tags>, but will exclude the tests rather than include
them. For example, if your network is down:

 my $test_suite = Test::Class::Moose->new({
     exclude_tags => [ 'network' ],
 });

 # or
 my $test_suite = Test::Class::Moose->new({
     exclude_tags => 'network',
 });


=head2 C<builder>

Usually defaults to C<< Test::Builder->new >>, but you could substitute your
own if it conforms to the interface.

=head2 C<randomize>

Boolean. Will run tests in a random order.

=head1 METHODS

=head2 C<args>

 my $tests = Some::Test::Class->new($test_suite->test_configuration->args);

Returns a hash reference of the args used to build the configuration. Used in
testing. You probably won't need it.

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

=cut

1;
