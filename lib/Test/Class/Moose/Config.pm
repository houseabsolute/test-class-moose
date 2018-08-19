package Test::Class::Moose::Config;

# ABSTRACT: Configuration information for Test::Class::Moose

use 5.010000;

our $VERSION = '0.94';

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use Test::Class::Moose::Deprecated;

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

has 'set_process_name' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
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
    is  => 'ro',
    isa => 'Str',
);

has 'randomize' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'randomize_classes' => (
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

    Test::Class::Moose::Deprecated::deprecated();

    return (
        map { defined $self->$_ ? ( $_ => $self->$_ ) : () }
        map { $_->name } $self->meta->get_all_attributes
    );
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 SYNOPSIS

 my $tc_config = Test::Class::Moose::Config->new({
     show_timing => 1,
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

=head2 C<show_timing>

Boolean. Will display verbose information on the amount of time it takes each
test class/test method to run.

=head2 C<statistics>

Boolean. Will display number of classes, test methods and tests run.

=head2 C<use_environment>

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


=head2 C<randomize>

Boolean. Will run test methods of a class in a random order.

=head2 C<randomize_classes>

Boolean. Will run test classes in a random order.

=head1 METHODS

=head2 C<args>

Returns a hash of the args used to build the configuration. This used to be
used internally, but is now retained simply for backwards compatibility. You
probably won't need it.

=cut

1;
