package Test::Class::Moose;

# ABSTRACT: Serious testing for serious Perl

use 5.10.0;
use Moose 2.0000;
use Carp;
use namespace::autoclean;
use Sub::Attribute;

use Test::Class::Moose::AttributeRegistry;
use Test::Class::Moose::Config;

has 'test_report' => (
    is     => 'rw',
    isa    => 'Test::Class::Moose::Report',
    writer => '__set_test_report',
);

sub __create_attributes {

    # XXX sharing this behavior here because my first attempt at creating a
    # role was a complete failure. MooseX::MethodAttributes can help here, but
    # I have to parse the attributes manually (as far as I can tell) and I
    # don't have the simple declarative style any more.
    return <<'DECLARE_ATTRIBUTES';
    sub Tags : ATTR_SUB {
        my ( $class, $symbol, undef, undef, $data, undef, $file, $line ) = @_;

        my @tags;
        if ($data) {
            $data =~ s/^\s+//g;
            @tags = split /\s+/, $data;
        }

        if ( $symbol eq 'ANON' ) {
            die "Cannot tag anonymous subs at file $file, line $line\n";
        }

        my $method = *{$symbol}{NAME};

        {    # block for localising $@
            local $@;

            Test::Class::Moose::AttributeRegistry->add_tags(
                $class,
                $method,
                \@tags,
            );
            if ($@) {
                croak "Error in adding tags: $@";
            }
        }
    }

    sub Test : ATTR_SUB {
        my ( $class, $symbol, undef, undef, undef, undef, $file, $line ) = @_;

        if ( $symbol eq 'ANON' ) {
            croak("Cannot add plans to anonymous subs at file $file, line $line");
        }

        my $method = *{$symbol}{NAME};
        if ( $method =~ /^test_(?:startup|setup|teardown|shutdown)$/ ) {
            croak("Test control method '$method' may not have a Test attribute");
        }

        Test::Class::Moose::AttributeRegistry->add_plan(
            $class,
            $method,
            1,
        );
        $class->meta->add_before_method_modifier($method, sub {
            my $test = shift;
            $test->test_report->plan(1);
        });
    }

    sub Tests : ATTR_SUB {
        my ( $class, $symbol, undef, undef, $data, undef, $file, $line ) = @_;

        if ( $symbol eq 'ANON' ) {
            croak("Cannot add plans to anonymous subs at file $file, line $line");
        }

        my $method = *{$symbol}{NAME};
        if ( $method =~ /^test_(?:startup|setup|teardown|shutdown)$/ ) {
            croak("Test control method '$method' may not have a Test attribute");
        }

        Test::Class::Moose::AttributeRegistry->add_plan(
            $class,
            $method,
            $data,
        );
        if ( defined $data ) {
            $class->meta->add_before_method_modifier($method, sub {
                my $test = shift;
                $test->test_report->plan($data);
            });
        }
    }
DECLARE_ATTRIBUTES
}

BEGIN {
    eval __PACKAGE__->__create_attributes;
    croak($@) if $@;
}

has 'test_class' => (
    is  => 'rw',
    isa => 'Str',
);

has 'test_skip' => (
    is      => 'rw',
    isa     => 'Str',
    clearer => 'test_skip_clear',
);

has '_config_p' => (
    is  => 'ro',
    isa => 'HashRef',
);

sub import {
    my ( $class, %arg_for ) = @_;
    my $caller = caller;

    my $preamble = <<"END";
package $caller;
use Moose;
use Test::Most;
use Sub::Attribute;
END

    eval $preamble;
    croak($@) if $@;
    strict->import;
    warnings->import;
    if ( my $parent
        = ( delete $arg_for{parent} || delete $arg_for{extends} ) )
    {
        my @parents = 'ARRAY' eq ref $parent ? @$parent : $parent;
        $caller->meta->superclasses(@parents);
    }
    else {
        $caller->meta->superclasses(__PACKAGE__);
    }
}

# XXX - this is only necessary for backwards compatibility, where people call
# Test::Class::Moose->new(...)->runtests() instead of
# Test::Class::Moose::Runner->new(...)->runtests()
my %config_attrs = map { $_->init_arg => 1}
    Test::Class::Moose::Config->meta->get_all_attributes;
around 'BUILDARGS' => sub {
    my $orig  = shift;
    my $class = shift;

    my $p = $class->$orig(@_);

    my %config_p
        = map { $_ => delete $p->{$_} } grep { $config_attrs{$_} } keys %{$p};
    $p->{_config_p} = \%config_p;

    return $p;
};

# XXX - also for backwards compat
sub runtests {
    my $self = shift;

    # The only way this object won't have a _runner set is if someone calls
    # ->new() on their test class (which subclasses Test::Class::Moose) and
    # then calls ->runtests() on it, which has never been documented as
    # working.
    carp 'Calling runtests() on a Test::Class::Moose object is deprecated.'
        . ' Use Test::Class::Moose::Runner instead.';

    require Test::Class::Moose::Runner;
    my $runner
        = Test::Class::Moose::Runner->new( $self->_config_p );

    return $runner->runtests();
}

sub BUILD {
    my $self = shift;

    # stash that name lest something change it later. Paranoid?
    $self->test_class( $self->meta->name );
}

sub _tcm_make_test_class_instances {
    my ( $test_class, $args ) = @_;

    return ( $test_class => $test_class->new($args) );
}

sub test_methods {
    my $self = shift;

    my @method_list;
    foreach my $method ( $self->meta->get_all_methods ) {

        # attributes cannot be test methods
        next if $method->isa('Moose::Meta::Method::Accessor');

        my $class = ref $self;
        my $name = $method->name;
        next
          unless $name =~ /^test_/
          || Test::Class::Moose::AttributeRegistry->has_test_attribute(
            $class, $name );

        # don't use anything defined in this package
        next if __PACKAGE__->can($name);
        push @method_list => $name;
    }

    return @method_list;
}

# empty stub methods guarantee that subclasses can always call these
sub test_startup  { }
sub test_setup    { }
sub test_teardown { }
sub test_shutdown { }

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

    package TestsFor::DateTime;
    use Test::Class::Moose;
    use DateTime;

    # methods that begin with test_ are test methods.
    sub test_constructor {
        my $test = shift;
        $test->test_report->plan(3);    # strictly optional

        can_ok 'DateTime', 'new';
        my %args = (
            year  => 1967,
            month => 6,
            day   => 20,
        );
        isa_ok my $date = DateTime->new(%args), 'DateTime';
        is $date->year, $args{year}, '... and the year should be correct';
    }

    1;

=head1 DESCRIPTION

See the L<Test::Class::Moose home page|http://test-class-moose.github.io/test-class-moose/> for
a summary.

C<Test::Class::Moose> is a powerful testing framework for Perl. Out of the box
you get:

=over 4

=item * Reporting

=item * Extensibility

=item * Tagging tests

=item * Parallel testing

=item * Test inheritance

=item * Write your tests using Moose

=item * All the testing functions and behavior from Test::Most

=item * Event handlers for startup, setup, teardown, and shutdown of test classes

=back

Better docs will come later. You should already know how to use Moose and
L<Test::Class>.

=head1 BASICS

=head2 Inheriting from Test::Class::Moose

Just C<use Test::Class::Moose>. That's all. You'll get all L<Test::Most> test
functions, too, along with C<strict> and C<warnings>. You can use all L<Moose>
behavior, too.

=head2 Declare a test method

All method names that begin with C<test_> are test methods. Methods that do
not are not test methods.

 sub test_this_is_a_method {
     my $test = shift;

     $test->this_is_not_a_test_method;
     ok 1, 'whee!';
 }

 sub this_is_not_a_test_method {
    my $test = shift;
    # but you can, of course, call it like normal
 }

You may specify C<Test> and C<Tests> method attributes, just like in
L<Test::Class> and the method will automatically be a test method, even if
does not start with C<test_>:

    sub this_is_a_test : Test {
        pass 'we have a single test';
    }

    sub another_test_method : Tests { # like "no_plan"
        # a bunch of tests
    }

    sub yet_another_test_method : Tests(7) { # sets plan to 7 tests
        ...
    }

B<Note>: Prior to version 0.51, this feature only worked if you had the
optional C<Sub::Attribute> installed.

=head2 Plans

No plans needed. The test suite declares a plan of the number of test classes.

Each test class is a subtest declaring a plan of the number of test methods.

Each test method relies on an implicit C<done_testing> call.

If you prefer, you can declare a plan in a test method:

    sub test_something {
        my $test = shift;
        $test->test_report->plan($num_tests);
        ...
    }

Or with a C<Tests> attribute:

    sub test_something : Tests(3) {
        my $test = shift;
        ...
    }

You may call C<plan()> multiple times for a given test method. Each call to
C<plan()> will add that number of tests to the plan.  For example, with a
method modifier:

    before 'test_something' => sub {
        my $test = shift;
        $test->test_report->plan($num_extra_tests);

        # more tests
    };

Please note that if you call C<plan>, the plan will still show up at the end
of the subtest run, but you'll get the desired failure if the number of tests
run does not match the plan.

=head2 Inheriting from another Test::Class::Moose class

List it as the C<extends> in the import list.

 package TestsFor::Some::Class::Subclass;
 use Test::Class::Moose extends => 'TestsFor::Some::Class';

 sub test_me {
     my $test  = shift;
     my $class = $test->test_class;
     ok 1, "I overrode my parent! ($class)";
 }

 before 'test_this_baby' => sub {
     my $test  = shift;
     my $class = $test->test_class;
     pass "This should run before my parent method ($class)";
 };

 sub this_should_not_run {
     my $test = shift;
     fail "We should never see this test";
 }

 sub test_this_should_be_run {
     for ( 1 .. 5 ) {
         pass "This is test number $_ in this method";
     }
 }

 1;

=head1 TEST CONTROL METHODS

Do not run tests in test control methods. This will cause the test control
method to fail (this is a feature, not a bug).  If a test control method
fails, the class/method will fail and testing for that class should stop.

B<Every> test control method will be called as a method. The invocant is the
instance of your test class

The available test control methods are:

=head2 C<test_startup>

 sub test_startup {
    my $test = shift;
    $test->next::method;
    # more startup
 }

Runs at the start of each test class. If you need to know the name of the
class you're running this in (though usually you shouldn't), use
C<< $test->test_class >>, or you can do this:

    sub test_startup {
        my $test                 = shift;
        my $report               = $test->test_report;
        my $class                = $report->current_class->name;
        my $upcoming_test_method = $report->current_method->name;
        ...
    }

The C<< $test->test_report >> object is a L<Test::Class::Moose::Report::Instance>
object.

=head2 C<test_setup>

 sub test_setup {
    my $test = shift;
    $test->next::method;
    # more setup
 }

Runs at the start of each test method. If you must know the name of the test
you're about to run, you can do this:

 sub test_setup {
    my $test = shift;
    $test->next::method;
    my $test_method = $test->test_report->current_method->name;
    # do something with it
 }

=head2 C<test_teardown>

 sub test_teardown {
    my $test = shift;
    # more teardown
    $test->next::method;
 }

Runs at the end of each test method.

=head2 C<test_shutdown>

 sub test_shutdown {
     my $test = shift;
     # more teardown
     $test->next::method;
 }

Runs at the end of each test class.

=head2 Overriding Test Control Methods

To override a test control method, just remember that this is OO:

 sub test_setup {
     my $test = shift;
     $test->next::method; # optional to call parent test_setup
     # more setup code here
 }

=head1 TEST CLASS INSTANCES

B<This feature is still considered experimental.>

By default, each test class you create will be instantiated once. However, you
can tell the L<Test::Class::Moose::Runner> to create multiple instances of a
test class.

To do this, simply consume the
L<Test::Class::Moose::Role::ParameterizedInstances> role in your test
class. This role requires you to implement a C<_constructor_parameter_sets>
method in your test class. That method will be called as a I<class method>. It
is expected to return a list of key/value pairs. The keys are the name of the
instance and the values are hashrefs of attributes to be passed to your test
class's constructor. Here's a really dumb example:

 package TestsFor::PlainAndFancy;
 use Test::Class::Moose;
 with 'Test::Class::Moose::Role::ParameterizedInstances';

 has is_fancy => (
     is       => 'ro',
     isa      => 'Bool',
     required => 1,
 );

 sub _constructor_parameter_sets {
     my $class = shift;
     return (
         "$class - plain" => { is_fancy => 0 },
         "$class - fancy" => { is_fancy => 1 },
     );
 }

 sub test_something { ... }

The test runner will run all the test methods in your class I<once per
instance>, and each instance will be run in its own subtest.

Note that this feature has great potential for abuse, so use it
cautiously. That said, there are cases where this feature can greatly simplify
your test code.

=head1 RUNNING THE TEST SUITE

See the docs for L<Test::Class::Moose::Runner> for details on running your
test suite. If you'd like to get up and running quickly, here's a very simple
test file you can use:

 use Test::Class::Moose::Load 't/lib';
 use Test::Class::Moose::Runner;
 Test::Class::Moose::Runner->new->runtests;

Put this in a file like F<t/run-test-class.t>. When you run it with prove it
will load all the test classes defined in F<t/lib> and run them sequentially.

=head2 Skipping Classes and Methods

If you wish to skip a class, set the reason in the C<test_startup> method.

    sub test_startup {
        my $test = shift;
        $test->test_skip("I don't want to run this class");
    }

If you wish to skip an individual method, do so in the C<test_setup> method.

    sub test_setup {
        my $test = shift;
        my $test_method = $test->test_report->current_method;

        if ( 'test_time_travel' eq $test_method->name ) {
            $test->test_skip("Time travel not yet available");
        }
    }

=head2 The "Tests" and "Test" Attributes

If you're comfortable with L<Test::Class>, you know that test methods methods are
declared in L<Test::Class> with C<Test> (for a method with a single test) or
C<Tests>, for a method with multiple tests. This also works for
C<Test::Class::Moose>. Test methods declared this way do not need to start
with C<test_>.

    sub something_we_want_to_check : Test {
        # this method may have only one test
    }

    sub something_else_to_check : Tests {
        # this method may have multiple tests
    }

    sub another_test_method : Tests(3) {
        # this method must have exactly 3 tests
    }

If a test method overrides a parent test method and calls it, their plans will
be added together:

    package TestsFor::Parent;

    use Test::Class::Moose;

    sub some_test : Tests(3) {
        # three tests
    }

And later:

    package TestsFor::Child;

    use Test::Class::Moose extends => 'TestsFor::Parent';

    sub some_test : Tests(2) {
        my $test = shift;
        $test->next::method;
        # 2 tests here
    }

In the above example, C<TestsFor::Parent::some_test> will run three tests, but
C<TestsFor::Child::some_test> will run I<five> tests (two tests, plus the
three from the parent).

Note that if a plan is explicitly declared, any modifiers or overriding
methods calling the original method will also have to assert the number of
tests to ensure the plan is correct. The above C<TestsFor::Parent> and
C<TestsFor::Child> code would fail if the child's C<some_test> method
attribute was C<Tests> without the number of tests asserted.

Do not use C<Test> or C<Tests> with test control methods because you don't run
tests in those.

=head2 Tagging Methods

Sometimes you want to be able to assign metadata to help you better manage
your test suite. You can do this with tags:

    sub test_save_poll_data : Tags(api network) {
        ...
    }

Tags are strictly optional and you can provide one or more tags for each test
method with a space separated list of tags. You can use this to filter your
tests suite, if desired. For example, if your network goes down and all tests
which rely on a network are tagged with C<network>, you can skip those tests
with this:

    Test::Class::Moose::Runner->new( exclude_tags => 'network' )->runtests;

Or maybe you want to run all C<api> and C<database> tests, but skip those
marked C<deprecated>:

    Test::Class::Moose::Runner->new(
        include_tags => [qw/api database/],
        exclude_tags => 'deprecated',
    )->runtests;

You can also inspect tags withing your test classes:

    sub test_setup {
        my $test          = shift;
        my $method_to_run = $test->test_report->current_method;
        if ( $method_to_run->has_tag('db') ) {
            $test->load_database_fixtures;
        }
    }

Tagging support relies on L<Sub::Attribute>. If this module is not available,
C<include_tags> and C<exclude_tags> will be ignored, but a warning will be
issued if those are seen. Prior to version 0.51, C<Sub::Attribute> was
optional. Now it's mandatory, so those features should always work.

=head1 THINGS YOU CAN OVERRIDE

... but probably shouldn't.

As a general rule, methods beginning with C</^test_/> are reserved for
L<Test::Class::Moose>. This makes it easier to remember what you can and
cannot override. However, any test with C<Test> or C<Tests> are test methods
regardless of their names.

=head2 C<test_report>

 my $report = $test->test_report;

Returns the L<Test::Class::Moose::Report> object. Useful if you want to do
your own reporting and not rely on the default output provided with the
C<statistics> boolean option.

You can also call it in test classes (most useful in the C<test_setup()> method):

    sub test_setup {
        my $test = shift;
        $self->next::method;
        my $report= $test->test_report;
        my $class = $test->current_class;
        my $method = $test->current_method; # the test method we're about to run
        if ( $method->name =~ /customer/ ) {
            $test->load_customer_fixture;
        }
        # or better still
        if ( $method->has_tag('customer') ) {
            $test->load_customer_fixture;
        }
    }

=head2 C<test_class>

 my $class = $test->test_class;

Returns the name for this test class. Useful if you rebless an object (such as
applying a role at runtime) and don't want to lose the original class name.

=head2 C<test_methods>

You may override this in a subclass. Currently returns all methods in a test
class that start with C<test_> (except for the test control methods).

Please note that the behavior for C<include> and C<exclude> is also contained
in this method. If you override it, you will need to account for those
yourself.

=head2 C<import>

Sadly, we have an C<import> method. This is used to automatically provide you
with all of the L<Test::Most> behavior.

=head1 SAMPLE TAP OUTPUT

We use nested tests (subtests) at each level:

    1..2
    #
    # Executing tests for TestsFor::Basic::Subclass
    #
        1..3
        # TestsFor::Basic::Subclass->test_me()
            ok 1 - I overrode my parent! (TestsFor::Basic::Subclass)
            1..1
        ok 1 - test_me
        # TestsFor::Basic::Subclass->test_this_baby()
            ok 1 - This should run before my parent method (TestsFor::Basic::Subclass)
            ok 2 - whee! (TestsFor::Basic::Subclass)
            1..2
        ok 2 - test_this_baby
        # TestsFor::Basic::Subclass->test_this_should_be_run()
            ok 1 - This is test number 1 in this method
            ok 2 - This is test number 2 in this method
            ok 3 - This is test number 3 in this method
            ok 4 - This is test number 4 in this method
            ok 5 - This is test number 5 in this method
            1..5
        ok 3 - test_this_should_be_run
    ok 1 - TestsFor::Basic::Subclass
    #
    # Executing tests for TestsFor::Basic
    #
        1..2
        # TestsFor::Basic->test_me()
            ok 1 - test_me() ran (TestsFor::Basic)
            ok 2 - this is another test (TestsFor::Basic)
            1..2
        ok 1 - test_me
        # TestsFor::Basic->test_this_baby()
            ok 1 - whee! (TestsFor::Basic)
            1..1
        ok 2 - test_this_baby
    ok 2 - TestsFor::Basic
    # Test classes:    2
    # Test methods:    5
    # Total tests run: 11
    ok
    All tests successful.
    Files=1, Tests=2,  2 wallclock secs ( 0.03 usr  0.00 sys +  0.27 cusr  0.01 csys =  0.31 CPU)
    Result: PASS

=head1 REPORTING

See L<Test::Class::Moose::Report> for more detailed information on reporting.

Reporting features are subject to change.

Sometimes you want more information about your test classes, it's time to do
some reporting. Maybe you even want some tests for your reporting. If you do
that, run the test suite in a subtest (because the plans will otherwise be
wrong).

    #!/usr/bin/env perl
    use lib 'lib';
    use Test::Most;
    use Test::Class::Moose::Load qw(t/lib);
    use Test::Class::Moose::Runner;

    my $test_suite = Test::Class::Moose::Runner->new;

    subtest 'run the test suite' => sub {
        $test_suite->runtests;
    };
    my $report = $test_suite->test_report;

    foreach my $class ( $report->all_test_instances ) {
        my $class_name = $class->name;
        ok !$class->is_skipped, "$class_name was not skipped";
        ok $class->passed, "$class_name passed";

        subtest "$class_name methods" => sub {
            foreach my $method ( $class->all_test_methods ) {
                my $method_name = $method->name;
                ok $method->passed, "$method_name passed";

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

If you just want to output reporting information, you do not need to run the
test suite in a subtest:

    my $test_suite = Test::Class::Moose::Runner->new->runtests;
    my $report     = $test_suite->test_report;
    ...

Or even shorter:

    my $report = Test::Class::Moose::Runner->new->runtests->test_report;

=head1 EXTRAS

If you would like L<Test::Class::Moose> to take care of loading your classes
for you, see L<Test::Class::Moose::Role::AutoUse> in this distribution.

=head1 DEPRECATIONS

=head2 Version 0.55

=over 4

=item * Running tests with Test::Class::Moose is deprecated - use L<Test::Class::Moose::Runner>

As of version 0.55, running tests and being a test class have been
separated. Your test classes should continue to C<use Test::Class::Moose>, but
your test runner script should use L<Test::Class::Moose::Runner>:

 use Test::Class::Moose::Load 't/lib';
 use Test::Class::Moose::Runner;
 Test::Class::Moose::Runner->new->runtests;

Calling C<< Test::Class::Moose->new->runtests >> still works, but is
deprecated and will issue a warning.

=item * Parallel testing is totally different

The C<Test::Class::Moose::Role::Parallel> role won't do anything other than
issue a warning. See the L<Test::Class::Moose::Runner> docs for details on
running tests in parallel.

=item * The L<Test::Class::Moose::Report> C<all_test_classes> method is deprecated

This has been replaced with the C<all_test_instances> method. The
C<all_test_classes> method is still present for backwards compatibility, but
it simply calls C<all_test_instances> under the hood.

=item * The C<Test::Class::Moose::Report::Class> class is gone

It has been replaced by the C<Test::Class::Moose::Report::Instance> class,
which has the same API.

=item * The C<Test::Class::Moose::Report::Method> C<class_report> method has been renamed

This is now called C<instance_report>.

=back

=head2 Version 0.40

=over 4

=item * C<test_reporting>

As of version 0.40, the long deprecated method C<test_reporting> has now been
removed.

=item * C<$report> argument to methods deprecated

Prior to version 0.40, you used to have a second argument to all test methods
and test control methods:

    sub test_something {
        my ( $test, $report ) = @_;
        ...
    }

This was annoying. It was doubly annoying in test control methods in case you
forgot it:

    sub test_setup {
        my ( $test, $report ) = @_;
        $test->next::method; # oops, needed $report
        ...
    }

That second argument is still passed, but it's deprecated. It's now
recommended that you call the C<< $test->test_report >> method to get that.
Instead of this:

    sub test_froblinator {
        my ( $test, $report ) = @_;
        $report->plan(7);
        ...
    }

You write this:

    sub test_froblinator {
        my $test = shift;
        $test->test_report->plan(7);
        ...
    }

=back

=head1 TODO

=over 4

=item * Callbacks for tags (for example, 'critical' tags could bailout)

=item *  New test phases - start and end suite, not just start and end class/method

=back

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

=head1 SEE ALSO

=over 4

=item * L<Test::Routine>

I always pointed people to this when they would ask about L<Test::Class> +
L<Moose>, but I would always hear "that's not quite what I'm looking for".
I don't quite understand what the reasoning was, but I strongly encourage you
to take a look at L<Test::Routine>.

=item * L<Test::Roo>

L<Test::Routine>, but with L<Moo> instead of L<Moose>.

=item * L<Test::Class>

xUnit-style testing in Perl.

=item * L<Test::Class::Most>

L<Test::Class> + L<Test::Most>.

=back

=head1 CONTRIBUTORS

=over 4

=item * Dave Rolsky <autarch@urth.org>

=item * Doug Bell <doug.bell@baml.com>

=item * Gregory Oschwald <goschwald@maxmind.com>

=item * Jonathan C. Otsuka <djgoku@gmail.com>

=item * Neil Bowers <neil@bowers.com>

=item * Olaf Alders <olaf@wundersolutions.com>

=item * Ovid <curtis\_ovid\_poe@yahoo.com>

=item * Paul Boyd <pboyd@dev3l.net>

=item * Petrea Corneliu Stefan <stefan@garage-coding.com>

=item * Stuckdownawell <stuckdownawell@gmail.com>

=item * Tom Beresford <tom.beresford@bskyb.com>

=item * Tom Heady <tom@punch.net>

=item * Udo Oji <Velti@signor.com>

=back

=cut
