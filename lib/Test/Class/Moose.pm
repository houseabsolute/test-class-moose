package Test::Class::Moose;

# ABSTRACT: Serious testing for serious Perl

use 5.10.0;
use Moose 2.0000;
use MooseX::ClassAttribute;
use Carp;
use List::Util qw(shuffle);
use List::MoreUtils qw(uniq);
use namespace::autoclean;
use Sub::Attribute;

use Test::Builder;
use Test::Most;
use Try::Tiny;
use Test::Class::Moose::Config;
use Test::Class::Moose::Report;
use Test::Class::Moose::Report::Class;
use Test::Class::Moose::Report::Method;
use Test::Class::Moose::AttributeRegistry;

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

has 'test_configuration' => (
    is  => 'ro',
    isa => 'Test::Class::Moose::Config',
);

has 'test_report' => (
    is      => 'rw',
    isa     => 'Test::Class::Moose::Report',
    writer  => '__set_test_report',
    default => sub { Test::Class::Moose::Report->new },
);

has 'test_class' => (
    is  => 'rw',
    isa => 'Str',
);

has 'test_skip' => (
    is      => 'rw',
    isa     => 'Str',
    clearer => 'test_skip_clear',
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

around 'BUILDARGS' => sub {
    my $orig  = shift;
    my $class = shift;
    return $class->$orig(
        { test_configuration => Test::Class::Moose::Config->new(@_) } );
};

sub BUILD {
    my $self = shift;

    # stash that name lest something change it later. Paranoid?
    $self->test_class( $self->meta->name );
}

my $TEST_CONTROL_METHODS = sub {
    local *__ANON__ = 'ANON_TEST_CONTROL_METHODS';
    return {
        map { $_ => 1 }
          qw/
          test_startup
          test_setup
          test_teardown
          test_shutdown
          /
    };
};

sub _tcm_run_test_method {
    my ( $self, $test_instance, $test_method, $report_class ) = @_;

    my $test_class = $test_instance->test_class;
    my $report  = Test::Class::Moose::Report::Method->new(
        { name => $test_method, report_class => $report_class } );
    $self->test_report->current_class->add_test_method($report);
    my $config = $self->test_configuration;

    my $builder = $config->builder;
    $test_instance->test_skip_clear;
    $test_instance->_tcm_run_test_control_method(
        'test_setup',
        $report
    ) or fail "test_setup failed";
    my $num_tests;

    Test::Most::explain("$test_class->$test_method()");
    $builder->subtest(
        $test_method,
        sub {
            if ( my $message = $test_instance->test_skip ) {
                $report->skipped($message);
                $builder->plan( skip_all => $message );
                return;
            }
            $report->_start_benchmark;

            my $old_test_count = $builder->current_test;
            try {
                $test_instance->$test_method($report);
                if ( $report->has_plan ) {
                    $builder->plan( tests => $report->tests_planned );
                }
            }
            catch {
                fail "$test_method failed: $_";
            };
            $num_tests = $builder->current_test - $old_test_count;

            $report->_end_benchmark;
            if ( $config->show_timing ) {
                my $time = $report->time->duration;
                $config->builder->diag(
                    $report->name . ": $time" );
            }
        },
    );

    $test_instance->_tcm_run_test_control_method(
        'test_teardown',
        $report
    ) or fail "test_teardown failed";
    if ( !$report->is_skipped ) {
        $report->num_tests_run($num_tests);
        if ( !$report->has_plan ) {
            $report->tests_planned($num_tests);
        }
    }
    return $report;
}

sub _tcm_run_test_control_method {
    my ( $self, $phase, $report_object ) = @_;

    $TEST_CONTROL_METHODS->()->{$phase}
      or croak("Unknown test control method ($phase)");

    my $success;
    my $builder = $self->test_configuration->builder;
    try {
        my $num_tests = $builder->current_test;
        $self->$phase($report_object);
        if ( $builder->current_test ne $num_tests ) {
            croak("Tests may not be run in test control methods ($phase)");
        }
        $success = 1;
    }
    catch {
        my $error = $_;
        my $class = $self->test_class;
        $builder->diag("$class->$phase() failed: $error");
    };
    return $success;
}

sub runtests {
    my $self = shift;

    my $report = $self->test_report;
    $report->_start_benchmark;
    my @test_classes = $self->test_classes;

    my $builder = $self->test_configuration->builder;
    $builder->plan( tests => scalar @test_classes );
    foreach my $test_class (@test_classes) {
        Test::Most::explain("\nRunning tests for $test_class\n\n");
        $builder->subtest(
            $test_class,
            $self->_tcm_run_test_class($test_class),
        );
    }

    $builder->diag(<<"END") if $self->test_configuration->statistics;
Test classes:    @{[ $report->num_test_classes ]}
Test methods:    @{[ $report->num_test_methods ]}
Total tests run: @{[ $report->num_tests_run ]}
END
    $builder->done_testing;
    $report->_end_benchmark;
    return $self;
}

sub _tcm_run_test_class {
    my ( $self, $test_class ) = @_;

    my $config  = $self->test_configuration;
    my $builder = $config->builder;
    my $report  = $self->test_report;

    return sub {
        local *__ANON__ = 'ANON_TCM_RUN_TEST_CLASS';

        # set up test class reporting
        my $report_class = Test::Class::Moose::Report::Class->new(
            {   name => $test_class,
            }
        );
        $report->add_test_class($report_class);
        my $test_instance
          = $test_class->new( $config->args );
        $test_instance->__set_test_report($report);

        my @test_methods = $test_instance->test_methods;
        unless (@test_methods) {
            my $message = "Skipping '$test_class': no test methods found";
            $report_class->skipped($message);
            $builder->plan( skip_all => $message );
            return;
        }
        $report_class->_start_benchmark;

        $report->_inc_test_methods( scalar @test_methods );

        # startup
        if (!$test_instance->_tcm_run_test_control_method(
                'test_startup', $report_class
            )
          )
        {
            fail "test_startup failed";
            return;
        }

        if ( my $message = $test_instance->test_skip ) {

            # test_startup skipped the class
            $report_class->skipped($message);
            $builder->plan( skip_all => $message );
            return;
        }

        $builder->plan( tests => scalar @test_methods );

        # run test methods
        foreach my $test_method (@test_methods) {
            my $report_method = $self->_tcm_run_test_method(
                $test_instance,
                $test_method,
                $report_class,
            );
            $report->_inc_tests( $report_method->num_tests_run );
        }

        # shutdown
        $test_instance->_tcm_run_test_control_method(
            'test_shutdown',
            $report_class
        ) or fail("test_shutdown() failed");

        # finalize reporting
        $report_class->_end_benchmark;
        if ( $config->show_timing ) {
            my $time = $report_class->time->duration;
            $config->builder->diag("$test_class: $time");
        }
    };
}

sub test_classes {
    my $self        = shift;

    if ( my $classes = $self->test_configuration->test_classes ) {
        if (@$classes) {    # ignore it if the array is empty
            return @$classes;
        }
    }

    my %metaclasses = Class::MOP::get_all_metaclasses();
    my @classes;
    foreach my $class ( keys %metaclasses ) {
        next if $class eq __PACKAGE__;
        push @classes => $class if $class->isa(__PACKAGE__);
    }

    # eventually we'll want to control the test class order
    return sort @classes;
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

    if ( my $include = $self->test_configuration->include ) {
        @method_list = grep {/$include/} @method_list;
    }
    if ( my $exclude = $self->test_configuration->exclude ) {
        @method_list = grep { !/$exclude/ } @method_list;
    }

    @method_list = $self->_tcm_filter_by_tag(\@method_list);

    return uniq(
        $self->test_configuration->randomize
        ? shuffle(@method_list)
        : sort @method_list
    );
}

sub _tcm_filter_by_tag {
    my ( $self, $methods ) = @_;
    my $class            = $self->test_class;
    my @filtered_methods = @$methods;
    if ( my $include = $self->test_configuration->include_tags ) {
        my @new_method_list;
        foreach my $method (@filtered_methods) {
            foreach my $tag (@$include) {
                if (Test::Class::Moose::AttributeRegistry->method_has_tag(
                        $class, $method, $tag
                    )
                  )
                {
                    push @new_method_list => $method;
                }
            }
        }
        @filtered_methods = @new_method_list;
    }
    if ( my $exclude = $self->test_configuration->exclude_tags ) {
        my @new_method_list = @filtered_methods;
        foreach my $method (@filtered_methods) {
            foreach my $tag (@$exclude) {
                if (
                    Test::Class::Moose::AttributeRegistry->method_has_tag(
                        $class, $method, $tag
                    )
                  )
                {
                  @new_method_list = grep { $_ ne $method } @new_method_list;
                }
            }
        };
        @filtered_methods = @new_method_list;
    };
    return @filtered_methods;
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

See the L<Test::Class::Moose home page|http://ovid.github.io/test-class-moose/> for
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

B<Every> test control method will be passed two arguments. The first is the
C<$test> invocant. The second is an object implementing
L<Test::Class::Moose::Role::Reporting>. You may find that the C<notes> hashref
is a handy way of recording information you later wish to use if you call C<<
$test_suite->test_report >>.

These are:

=over 4

=item * C<test_startup>

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

The C<< $test->test_report >> object is a L<Test::Class::Moose::Report::Class>
object.

=item * C<test_setup>

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

=item * C<test_teardown>

 sub test_teardown {
    my $test = shift;
    # more teardown
    $test->next::method;
 }

Runs at the end of each test method. 

=item * C<test_shutdown>

 sub test_shutdown {
     my $test = shift;
     # more teardown
     $test->next::method;
 }

Runs at the end of each test class. 

=back

To override a test control method, just remember that this is OO:

 sub test_setup {
     my $test = shift;
     $test->next::method; # optional to call parent test_setup
     # more setup code here
 }

=head1 RUNNING THE TEST SUITE

We I<strongly> recommend using L<Test::Class::Moose::Load> as the driver for
your test suite. Simply point it at the directory or directories containing
your test classes:

 use Test::Class::Moose::Load 't/lib';
 My::Base::Class->new->runtests;

By running C<Test::Class::Moose> with a single driver script like this, all
classes are loaded once and this can be a significant performance boost. This
does mean a global state will be shared, so keep this in mind.

You can also pass arguments to C<Test::Class::Moose>'s contructor.

 my $test_suite = My::Base::Class->new({
     show_timing => 1,
     randomize   => 0,
     statistics  => 1,
 });
 # do something
 $test_suite->runtests;

The attributes passed in the constructor are not directly available from the
L<Test::Class::Moose> instance. They're available in
L<Test::Class::Moose::Config> and to avoid namespace pollution, we do I<not>
delegate the attributes directly as a result. If you need them at runtime,
you'll need to access the C<test_configuration> attribute:

 my $builder = $test_suite->test_configuration->builder;

Note that you can call C<< Test::Class::Moose->new >> instead of 
C<< My::Base::Class->new >>, but we recommend that you instantiate an instance
of your base class instead of C<Test::Class::Moose>. There are times when you
may apply a role to your base class and modify it, but running it in the
context of C<Test::Class::Moose> will not always pick up those modifications.

In other words, create an instance of your base class, not
C<Test::Class::Moose>.

=head2 Contructor Attributes

=over 4

=item * C<show_timing>

Boolean. Will display verbose information on the amount of time it takes each
test class/test method to run. Defaults to false, but see C<use_environment>.

=item * C<statistics>

Boolean. Will display number of classes, test methods and tests run. Defaults
to false, but see C<use_environment>.

=item * C<use_environment>

If this is true, then the default value for show_timing and statistics will be
true if the C<HARNESS_IS_VERBOSE> environment variable is true. This is set
when running C<prove -v ...>, for example.

=item * C<randomize>

Boolean. Will run test methods in a random order.

=item * C<builder>

Defaults to C<< Test::Builder->new >>. You can supply your own builder if you
want, but it must conform to the L<Test::Builder> interface. We make no
guarantees about which part of the interface it needs.

=item * C<test_classes>

Takes a class name or an array reference of class names. If it is present,
only these test classes will be run. This is very useful if you wish to run an
individual class as a test:

    My::Base::Class->new(
        test_classes => $ENV{TEST_CLASS}, # ignored if undef
    )->runtests;

You can also achieve this effect by writing a subclass and overriding the
C<test_classes> method, but this makes it trivial to do this:

    TEST_CLASS=TestsFor::Our::Company::Invoice prove -lv t/test_classes.t

Alternatively:

    My::Base::Class->new(
        test_classes => \@ARGV, # ignored if empty
    )->runtests;

That lets you use the arisdottle to provide arguments to your test driver
script:

    prove -lv t/test_classes.t :: TestsFor::Our::Company::Invoice TestsFor::Something::Else

=item * C<include>

Regex. If present, only test methods whose name matches C<include> will be
included. B<However>, they must still start with C<test_>.

For example:

 my $test_suite = Test::Class::Moose->new({
     include => qr/customer/,
 });

The above constructor will let you match test methods named C<test_customer>
and C<test_customer_account>, but will not suddenly match a method named
C<default_customer>.

By enforcing the leading C<test_> behavior, we don't surprise developers who
are trying to figure out why C<default_customer> is being run as a test. This
means an C<include> such as C<< /^customer.*/ >> will never run any tests.

=item * C<exclude>

Regex. If present, only test methods whose names don't match C<exclude> will be
included. B<However>, they must still start with C<test_>. See C<include>.

=item * C<include_tags>

Array ref of strings matching method tags (a single string is also ok). If
present, only test methods whose tags match C<include_tags> or whose tags
don't match C<exclude_tags> will be included. B<However>, they must still
start with C<test_>.

For example:

 my $test_suite = Test::Class::Moose->new({
     include_tags => [qw/api database/],
 });

The above constructor will only run tests tagged with C<api> or C<database>.

=item * C<exclude_tags>

The same as C<include_tags>, but will exclude the tests rather than include
them. For example, if your network is down:

 my $test_suite = Test::Class::Moose->new({
     exclude_tags => [ 'network' ],
 });

 # or
 my $test_suite = Test::Class::Moose->new({
     exclude_tags => 'network',
 });

=back

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

If you're comfortable with L<Test::Class>, know test methods methods are
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

Do not use C<Test> or C<Tests> with test control methods becase you don't run
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

    My::Base::Class->new( exclude_tags => 'network' )->runtests;

Or maybe you want to run all C<api> and C<database> tests, but skip those
marked C<deprecated>:

    My::Base::Class->new(
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

=head1 PARALLEL TESTING

If you want to run the tests in parallel, see the experimental
C<Test::Class::Moose::Role::Parallel> role. Read the documentation carefully
as it can take a while to understand. You only need to use the role and
(optionally) provide a C<schedule()> method. Any tests tagged with
C<noparallel> will be run sequentially after the parallel tests (unless you
provide your own schedule, in which case you can do anything you want).

=head1 THINGS YOU CAN OVERRIDE

... but probably shouldn't.

As a general rule, methods beginning with C</^test_/> are reserved for
L<Test::Class::Moose>. This makes it easier to remember what you can and
cannot override. However, any test with C<Test> or C<Tests> are test methods
regardless of their names.

=head2 C<test_configuration>

 my $test_configuration = $test->test_configuration;

Returns the L<Test::Class::Moose::Config> object.

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

=head2 C<test_classes>

You may override this in a subclass. Currently returns a sorted list of all
loaded classes that inherit directly or indirectly through
L<Test::Class::Moose>

=head2 C<test_methods>

You may override this in a subclass. Currently returns all methods in a test
class that start with C<test_> (except for the test control methods).

Please note that the behavior for C<include> and C<exclude> is also contained
in this method. If you override it, you will need to account for those
yourself.

=head2 C<runtests>

If you really, really want to change how this module works, you can override
the C<runtests> method. We don't recommend it.

Returns the L<Test::Class::Moose> instance.

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
    my $test_suite = My::Base::Class->new;

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

If you just want to output reporting information, you do not need to run the
test suite in a subtest:

    my $test_suite = My::Base::Class->new->runtests;
    my $report     = $test_suite->test_report;
    ...

Or even shorter:

    my $report = My::Base::Class->new->runtests->test_report;

=head1 EXTRAS

If you would like L<Test::Class::Moose> to take care of loading your classes
for you, see L<Test::Class::Moose::Role::AutoUse> in this distribution.

=head1 DEPRECATIONS

=over 4

=item * C<test_reporting>

As of version .40, the long deprecated method C<test_reporting> has now been
removed.

=item * C<$report> argument to methods deprecated

Prior to version .40, you used to have a second argument to all test methods
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
