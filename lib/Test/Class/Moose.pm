package Test::Class::Moose;

use 5.10.0;
use Moose;
use Benchmark qw(timediff timestr);
use Carp;
use List::Util qw(shuffle);
use namespace::autoclean;
use Test::Builder;
use Test::Most;
use Try::Tiny;
use Test::Class::Moose::Config;
use Test::Class::Moose::Reporting;
use Test::Class::Moose::Reporting::Class;
use Test::Class::Moose::Reporting::Method;

our $VERSION = 0.02;

has 'configuration' => (
    is  => 'ro',
    isa => 'Test::Class::Moose::Config',
);

has 'reporting' => (
    is  => 'ro',
    isa => 'Test::Class::Moose::Reporting',
);

has 'this_class' => (
    is  => 'rw',
    isa => 'Str',
);

sub import {
    my ( $class, %arg_for ) = @_;
    my $caller = caller;

    eval <<"END";
package $caller;
use Test::Most;
use Moose;
END
    croak($@) if $@;
    strict->import;
    warnings->import;
    if ( my $parent = ( delete $arg_for{parent} || delete $arg_for{extends} ) )
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
        {   configuration => Test::Class::Moose::Config->new(@_),
            reporting     => Test::Class::Moose::Reporting->new,
        }
    );
};

sub BUILD {
    my $self = shift;

    # stash that name lest something change it later. Paranoid?
    $self->this_class( $self->meta->name );
}

my $test_control_methods = sub {
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

my $run_test_control_method = sub {
    my ( $self, $phase, $maybe_test_method ) = @_;

    $test_control_methods->()->{$phase}
      or croak("Unknown test control method ($phase)");

    my $success;
    my $builder = $self->configuration->builder;
    try {
        my $num_tests = $builder->current_test;
        $self->$phase($maybe_test_method);
        if ( $builder->current_test ne $num_tests ) {
            croak("Tests may not be run in test control methods ($phase)");
        }
        $success = 1;
    }
    catch {
        my $error = $_;
        my $class = $self->this_class;
        $builder->diag("$class->$phase() failed: $error");
    };
    return $success;
};

my $run_test_method = sub {
    my ( $self, $test_instance, $test_method ) = @_;

    my $test_class = $test_instance->this_class;
    my $reporting_method =
      Test::Class::Moose::Reporting::Method->new( { name => $test_method } );

    $test_instance->$run_test_control_method(
        'test_setup',
        $reporting_method
    );
    my $num_tests;

    my $builder = $self->configuration->builder;
    Test::Most::explain("$test_class->$test_method()"), $builder->subtest(
        $test_method,
        sub {
            my $start = Benchmark->new;
            $reporting_method->start_benchmark($start);

            my $old_test_count = $builder->current_test;
            try {
                $test_instance->$test_method;
            }
            catch {
                fail "$test_method failed: $_";
            };
            $num_tests = $builder->current_test - $old_test_count;

            my $end = Benchmark->new;
            $reporting_method->end_benchmark($end);
            if ( $self->configuration->show_timing ) {
                my $time = timestr( timediff( $end, $start ) );
                $self->configuration->builder->diag(
                    $reporting_method->name . ": $time" );
            }
        },
    );
    $test_instance->$run_test_control_method(
        'test_teardown',
        $reporting_method
    );
    $self->reporting->current_class->add_test_method($reporting_method);
    $reporting_method->num_tests($num_tests);
    return $reporting_method;
};

sub runtests {
    my $self = shift;

    my @test_classes = $self->get_test_classes;
    my $builder      = $self->configuration->builder;
    my $reporting    = $self->reporting;

    $builder->plan( tests => scalar @test_classes );
    foreach my $test_class (@test_classes) {
        Test::Most::explain("\nExecuting tests for $test_class\n\n"),
          $builder->subtest(
            $test_class,
            sub {
                my $test_instance =
                  $test_class->new( $self->configuration->args );
                my $reporting_class =
                  Test::Class::Moose::Reporting::Class->new(
                    {   name => $test_class,
                    }
                  );
                $reporting->add_test_class($reporting_class);
                my @test_methods = $test_instance->get_test_methods;
                unless (@test_methods) {
                    my $message =
                      "Skipping '$test_class': no test methods found";
                    $reporting_class->skipped($message);
                    $builder->plan( skip_all => $message);
                    return;
                }
                my $start = Benchmark->new;
                $reporting_class->start_benchmark($start);

                $reporting->inc_test_methods( scalar @test_methods );

                if (!$test_instance->$run_test_control_method(
                        'test_startup', $reporting_class
                    )
                  )
                {
                    fail "test_startup failed";
                    return;
                }

                $builder->plan( tests => scalar @test_methods );

                foreach my $test_method (@test_methods) {
                    my $reporting_method = $self->$run_test_method(
                        $test_instance,
                        $test_method
                    );
                    $reporting->inc_tests( $reporting_method->num_tests );
                }
                $test_instance->$run_test_control_method( 'test_shutdown',
                    $reporting_class )
                  or fail("test_shutdown() failed");

                my $end = Benchmark->new;
                $reporting_class->end_benchmark($end);
                if ( $self->configuration->show_timing ) {
                    my $time = timestr( timediff( $end, $start ) );
                    $self->configuration->builder->diag("$test_class: $time");
                }
            }
          );
    }
    $builder->diag(<<"END") if $self->configuration->statistics;
Test classes:    @{[ $reporting->num_test_classes ]}
Test methods:    @{[ $reporting->num_test_methods ]}
Total tests run: @{[ $reporting->num_tests ]}
END
    $builder->done_testing;
}

sub get_test_classes {
    my $self        = shift;
    my %metaclasses = Class::MOP::get_all_metaclasses();
    my @classes;
    while ( my ( $class, $metaclass ) = each %metaclasses ) {
        next unless $metaclass->can('superclasses');
        next if $class eq __PACKAGE__;
        next if $class eq 'main';        # XXX track down this bug

        push @classes => $class
          if grep { $_ eq __PACKAGE__ } $metaclass->linearized_isa;
    }

    # eventually we'll want to control the test class order
    return sort @classes;
}

sub get_test_methods {
    my $self = shift;

    my @method_list =
      grep { /^test_/ and not $test_control_methods->()->{$_} }
      $self->meta->get_method_list;

    # eventually we'll want to control the test method order

    if ( my $include = $self->configuration->include ) {
        @method_list = grep {/$include/} @method_list;
    }
    if ( my $exclude = $self->configuration->exclude ) {
        @method_list = grep { !/$exclude/ } @method_list;
    }

    return ( $self->configuration->randomize )
      ? shuffle(@method_list)
      : sort @method_list;
}

# empty stub methods guarantee that subclasses can always call these
sub test_startup  { }
sub test_setup    { }
sub test_teardown { }
sub test_shutdown { }

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Test::Class::Moose - Test::Class + Moose

=head1 VERSION

0.02

=head1 SYNOPSIS

 package TestsFor::Some::Class;
 use Test::Class::Moose;

 sub test_me {
     my $test  = shift;
     my $class = $test->this_class;
     ok 1, "test_me() ran ($class)";
     ok 2, "this is another test ($class)";
 }

 sub test_this_baby {
     my $test  = shift;
     my $class = $test->this_class;
     is 2, 2, "whee! ($class)";
 }

 1;

=head1 DESCRIPTION

This is B<ALPHA> code. I encourage you to give it a shot if you want test
classes based on Moose, along with reporting. Feedback welcome as we try to
improve it.

This is a proof of concept for writing Test::Class-style tests with Moose.
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

=head2 Plans

No plans needed. The test suite declares a plan of the number of test classes.

Each test class is a subtest declaring a plan of the number of test methods.

Each test method relies on an implicit C<done_testing> call.

=head2 Inheriting from another Test::Class::Moose class

List it as the C<extends> in the import list.

 package TestsFor::Some::Class::Subclass;
 use Test::Class::Moose extends => 'TestsFor::Some::Class';

 sub test_me {
     my $test  = shift;
     my $class = $test->this_class;
     ok 1, "I overrode my parent! ($class)";
 }

 before 'test_this_baby' => sub {
     my $test  = shift;
     my $class = $test->this_class;
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
C<Test::Class::Moose::Role::Reporting>. You may find that the C<notes> hashref
is a handy way of recording information you later wish to use if you call
C<< $test_suite->reporting >>.

These are:

=over 4

=item * C<test_startup>

 sub test_startup {
    my ( $test, $reporting ) = @_;
    $test->next::method;
    # more startup
 }

Runs at the start of each test class. If you need to know the name of the
class you're running this in (though usually you shouldn't), use
C<< $test->this_class >>, or the C<name> method on the C<$reporting> object.

The C<$reporting> object is a C<Test::Class::Moose::Reporting::Class> object.

=item * C<test_setup>

 sub test_setup {
    my ( $test, $reporting ) = @_;
    $test->next::method;
    # more setup
 }

Runs at the start of each test method. If you must know the name of the test
you're about to run, you can call C<< $reporting->name >>.

The C<$reporting> object is a C<Test::Class::Moose::Reporting::Method> object.

=item * C<test_teardown>

 sub test_teardown {
    my ( $test, $reporting ) = @_;
    # more teardown
    $test->next::method;
 }

Runs at the end of each test method. 

The C<$reporting> object is a C<Test::Class::Moose::Reporting::Method> object.

=item * C<test_shutdown>

 sub test_shutdown {
     my ( $test, $reporting ) = @_;
     # more teardown
     $test->next::method;
 }

Runs at the end of each test class. 

The C<$reporting> object is a C<Test::Class::Moose::Reporting::Class> object.

=back

To override a test control method, just remember that this is OO:

 sub test_setup {
     my $test = shift;
     $test->next::method; # optional to call parent test_setup
     # more setup code here
 }

=head1 RUNNING THE TEST SUITE

We have a constructor now:

 use Test::Class::Moose::Load 't/lib';
 Test::Class::Moose->new->runtests

Or:

 my $test_suite = Test::Class::Moose->new({
     show_timing => 1,
     randomize   => 0,
     statistics  => 1,
 });
 # do something
 $test_suite->runtests;

Note that in reality, the above is sort of equivalent to:

 my $test_suite = Test::Class::Moose->new({
     configuration => Test::Class::Moose::Config->new({
         show_timing => 1,
         randomize   => 0,
         statistics  => 1,
     }),
 });
 # do something
 $test_suite->runtests;

But you can't call it like that.

By pushing the attributes to L<Test::Class::Moose::Config>, we avoid namespace
pollution. We do I<not> delegate the attributes directly as a result. If you
need them at runtime, you'll need to access the C<configuration> attribute:

 my $builder = $test_suite->configuration->builder;

Attributes to it:

=over 4

=item * C<show_timing>

Boolean. Will display verbose information on the amount of time it takes each
test class/test method to run.

=item * C<statistics>

Boolean. Will display number of classes, test methods and tests run.

=item * C<randomize>

Boolean. Will run test methods in a random order.

=item * C<builder>

Defaults to C<< Test::Builder->new >>. You can supply your own builder if you
want, but it must conform to the C<Test::Builder> interface. We make no
guarantees about which part of the interface it needs.

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

=back

=head1 THINGS YOU CAN OVERRIDE

=head2 Attributes

=head3 C<configuration>

 my $configuration = $test->configuration;

Returns the C<Test::Class::Moose::Config> object.

=head3 C<reporting>

 my $reporting = $test->reporting;

Returns the C<Test::Class::Moose::Reporting> object. Useful if you want to do
your own reporting and not rely on the default output provided with the
C<statistics> boolean option.

=head3 C<this_class>

 my $class = $test->this_class;

Returns the name for this class. Useful if you rebless an object (such as
applying a role at runtime) and lose the original class name.

=head2 METHODS

=head3 C<get_test_classes>

You may override this in a subclass. Currently returns a sorted list of all
loaded classes that inherit directly or indirectly through
C<Test::Class::Moose>

=head3 C<get_test_methods>

You may override this in a subclass. Currently returns all methods in a test
class that start with C<test_> (except for the test control methods).

Please note that the behavior for C<include> and C<exclude> is also contained
in this method. If you override it, you will need to account for those
yourself.

=head3 C<runtests>

If you really, really want to change how this module works, you can override
the C<runtests> method. We don't recommend it.

=head3 C<import>

Sadly, we have an C<import> method. This is used to automatically provide you
with all of the C<Test::Most> behavior.

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

Reporting features are subject to change.

Sometimes you want more information about your test classes, it's time to do
some reporting. Maybe you even want some tests for your reporting. If you do
that, run the test suite in a subtest.

    #!/usr/bin/env perl
    use lib 'lib';
    use Test::Most;
    use Test::Class::Moose::Load qw(t/lib);
    my $test_suite = Test::Class::Moose->new;

    subtest 'run the test suite' => sub {
        $test_suite->runtests;
    };
    my $reporting = $test_suite->reporting;

    foreach my $class ( $reporting->all_test_classes ) {
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
    diag "Number of test classes: " . $reporting->num_test_classes;
    diag "Number of test methods: " . $reporting->num_test_methods;
    diag "Number of tests:        " . $reporting->num_tests;

    done_testing;

=head1 TODO

=over 4

=item * Load classes

 Test::Class::Moose->new({
    load => sub {
        my $test  = shift;
        my $class = $test->this_class;
        $class    =~ s/^TestsFor:://;
        return $class;
    },
 })->runtests;
 
If present, takes a sub that returns a classname we'll attempt to
automatically load. Completely optional, of course. And then in your test:

 sub test_something {
     my $test   = shift;
     my $class  = $test->class_to_test;
     my $object = $class->new;
     ok ...
 }

Because it's an attribute, you can merely declare it in a subclass, if you
prefer, or override it in a subclass (in other words, this is OO code and you,
the developer, will have full control over it).

=item * Make it easy to skip an entire class

=back

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
