package Test::Class::Moose;

use 5.10.0;
use Moose;
use Carp;
use Test::Builder;
use Benchmark qw(timediff timestr);
use namespace::autoclean;
use Try::Tiny;

has 'show_timing' => (
    is  => 'ro',
    isa => 'Bool',
);
has 'builder' => (
    is      => 'ro',
    isa     => 'Test::Builder',
    default => sub {
        Test::Builder->new;
    },
);
has 'statistics' => (
    is  => 'ro',
    isa => 'Bool',
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
    if ( my $parent = delete $arg_for{parent} ) {
        my @parents = 'ARRAY' eq ref $parent ? @$parent : $parent;
        $caller->meta->superclasses(@parents);
    }
    else {
        $caller->meta->superclasses(__PACKAGE__);
    }
}

sub BUILD {
    my $self = shift;

    # stash that name lest something change it later. Paranoid?
    $self->this_class( $self->meta->name );
}

my $time_this = sub {
    my ( $self, $name, $sub ) = @_;
    my $start = Benchmark->new;
    $sub->();
    if ( $self->show_timing ) {
        my $time = timestr( timediff( Benchmark->new, $start ) );
        $self->builder->diag("$name: $time");
    }
};

my $run_test_method = sub {
    my ( $self, $test_instance, $test_method ) = @_;

    my $test_class = $test_instance->this_class;

    $test_instance->test_setup;
    my $num_tests;

    my $builder = $self->builder;
    Test::Most::explain("$test_class->$test_method()"), $builder->subtest(
        $test_method,
        sub {
            $self->$time_this(
                "Runtime $test_class\::$test_method",
                sub {
                    my $old_test_count = $builder->current_test;
                    $test_instance->$test_method;
                    $num_tests = $builder->current_test - $old_test_count;
                },
            );
        },
    );
    $test_instance->test_teardown;
    return $num_tests;
};

sub runtests {
    my $self = shift;

    my @test_classes = $self->get_test_classes;
    my $builder      = $self->builder;

    my $num_test_classes = @test_classes;
    $builder->plan( tests => $num_test_classes );
    my ( $num_test_methods, $num_tests ) = ( 0, 0 );
    foreach my $test_class (@test_classes) {
        Test::Most::explain("\nExecuting tests for $test_class\n\n"),
          $builder->subtest(
            $test_class,
            sub {
                $self->$time_this(
                    "Runtime for $test_class",
                    sub {
                        my $test_instance = $test_class->new;
                        $test_instance->test_startup;

                        my @test_methods = $test_instance->get_test_methods;
                        $num_test_methods += @test_methods;
                        $builder->plan( tests => scalar @test_methods );

                        foreach my $test_method (@test_methods) {
                            $num_tests += $self->$run_test_method(
                                $test_instance,
                                $test_method
                            );
                        }
                        $test_instance->test_shutdown;
                    }
                );
            }
          );
    }
    $builder->diag(<<"END") if $self->statistics;
Test classes:    $num_test_classes
Test methods:    $num_test_methods
Total tests run: $num_tests
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
    return @classes;
}

sub get_test_methods {
    my $self = shift;

    state $is_test_control_method
      = { map { ; "test_$_" => 1 } qw/startup setup teardown shutdown/ };

    # eventuall we'll want to control the test method order
    return
      sort grep { /^test_/ and not $is_test_control_method->{$_} }
      $self->meta->get_method_list;
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

This is B<ALPHA> code. It is not production ready. An exception will take down
your test suite.

This is a tiny proof of concept for writing Test::Class-style tests with
Moose. Better docs will come later. You should already know how ot use Moose
and Test::Class.

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

List it as the C<parent> in the import list.

 package TestsFor::Some::Class::Subclass;
 use Test::Class::Moose parent => 'TestsFor::Some::Class';

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

Do not run tests in test control methods. They are not needed and in the
future, will cause test failures. If a test control method fails, the
class/method should fail. Currently we do not trap exceptions, so your entire
test suite will break. Yes, this is a bug and will be fixed later.

These are:

=over 4

=item * C<test_startup>

Runs at the start of each test class

=item * C<test_setup>

Runs at the start of each test method

=item * C<test_teardown>

Runs at the end of each test method

=item * C<test_shutdown>

Runs at the end of each test class

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

Attributes to it:

=over 4

=item * C<show_timing>

Boolean. Will display verbose information on the amount of time it takes each
test class/test method to run.

=item * C<statistics>

Boolean. Will display number of classes, test methods and tests run.

=back

=head1 ATTRIBUTES

=head2 C<builder>

 my $builder = $test->builder;

Returns the Test::Builder object.

=head2 C<this_class>

 my $class = $test->this_class;

Returns the name for this class. Useful if you rebless an object (such as
applying a role at runtime) and lose the original class name.

=head1 METHODS

=head2 C<get_test_classes>

You may override this in a subclass. Currently returns all loaded classes that
inherit directly or indirectly through C<Test::Class::Moose>

=head2 C<get_test_methods>

You may override this in a subclass. Currently returns all methods in a test
class that start with C<test_> (except for the test control methods).

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

=head1 TODO

=over 4

=item * Add C<Test::Class::Moose::Reporting>

Gather up the reporting in one module rather than doing it on an ad-hoc basis.

=item * Test method filtering

 Test::Class::Moose->new({
     include => qr/customer/,
     exclude => qr/database/,
 })->runtests;

=item * Trap exceptions (duh!)

Currently exceptions kill the test suite.

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

=back
