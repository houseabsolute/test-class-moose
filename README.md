# NAME

Test::Class::Moose - Test::Class + Moose

# VERSION

0.02

# SYNOPSIS

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

# DESCRIPTION

This is __ALPHA__ code. It is not production ready, but the basics seem to work
well.

This is a tiny proof of concept for writing Test::Class-style tests with
Moose. Better docs will come later. You should already know how to use Moose
and Test::Class.

# BASICS

## Inheriting from Test::Class::Moose

Just `use Test::Class::Moose`. That's all. You'll get all [Test::Most](http://search.cpan.org/perldoc?Test::Most) test
functions, too, along with `strict` and `warnings`. You can use all [Moose](http://search.cpan.org/perldoc?Moose)
behavior, too.

## Declare a test method

All method names that begin with `test_` are test methods. Methods that do
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

## Plans

No plans needed. The test suite declares a plan of the number of test classes.

Each test class is a subtest declaring a plan of the number of test methods.

Each test method relies on an implicit `done_testing` call.

## Inheriting from another Test::Class::Moose class

List it as the `extends` (or `parent`) in the import list.

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

# TEST CONTROL METHODS

Do not run tests in test control methods. They are not needed and in the
future, will cause test failures. If a test control method fails, the
class/method will fail and testing for that class should stop.

__Every__ test control method will be passed two arguments. The first is the
`$test` invocant. The second is an object implementing
`Test::Class::Moose::Reporting::Role::Reporting`. Find that the `notes`
hashref is a handy way of recording information you later wish to use if you
call `$test_suite->reporting`.

These are:

- `test_startup`

    sub test_startup {
       my ( $test, $reporting ) = @_;
       $test->next::method;
       # more startup
    }

Runs at the start of each test class. If you need to know the name of the
class you're running this in (though usually you shouldn't), the use
`$test->this_class`, or the `name` method on the `$reporting` object.

The `$reporting` object is a `Test::Class::Moose::Reporting::Class` object.

- `test_setup`

    sub test_setup {
       my ( $test, $reporting ) = @_;
       $test->next::method;
       # more setup
    }

Runs at the start of each test method. If you must know the name of the test
you're about to run, you can call `$reporting->name >.
`

The `$reporting` object is a `Test::Class::Moose::Reporting::Method` object.

- `test_teardown`

    sub test_teardown {
       my ( $test, $reporting ) = @_;
       # more teardown
       $test->next::method;
    }

Runs at the end of each test method. 

The `$reporting` object is a `Test::Class::Moose::Reporting::Method` object.

- `test_shutdown`

    sub test_shutdown {
        my ( $test, $reporting ) = @_;
        # more teardown
        $test->next::method;
    }

Runs at the end of each test class. 

The `$reporting` object is a `Test::Class::Moose::Reporting::Class` object.

To override a test control method, just remember that this is OO:

    sub test_setup {
        my $test = shift;
        $test->next::method; # optional to call parent test_setup
        # more setup code here
    }

# RUNNING THE TEST SUITE

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

By pushing the attributes to [Test::Class::Moose::Config](http://search.cpan.org/perldoc?Test::Class::Moose::Config), we avoid namespace
pollution. We do _not_ delegate the attributes directly as a result. If you
need them at runtime, you'll need to access the `configuration` attribute:

    my $builder = $test_suite->configuration->builder;

Attributes to it:

- `show_timing`

Boolean. Will display verbose information on the amount of time it takes each
test class/test method to run.

- `statistics`

Boolean. Will display number of classes, test methods and tests run.

- `randomize`

Boolean. Will run test methods in a random order.

- `builder`

Defaults to `Test::Builder->new`. You can supply your own builder if you
want, but it must conform to the `Test::Builder` interface. We make no
guarantees about which part of the interface it needs.

- `include`

Regex. If present, only test methods whose name matches `include` will be
included. __However__, they must still start with `test_`.

For example:

    my $test_suite = Test::Class::Moose->new({
        include => qr/customer/,
    });

The above constructor will let you match test methods named `test_customer`
and `test_customer_account`, but will not suddenly match a method named
`default_customer`.

By enforcing the leading `test_` behavior, we don't surprise developers who
are trying to figure out why `default_customer` is being run as a test. This
means an `include` such as `/^customer.*/` will never run any tests.

- `exclude`

Regex. If present, only test methods whose names don't match `exclude` will be
included. __However__, they must still start with `test_`. See `include`.

# THINGS YOU CAN OVERRIDE

## Attributes

### `configuration`

    my $configuration = $test->configuration;

Returns the `Test::Class::Moose::Config` object.

### `reporting`

    my $reporting = $test->reporting;

Returns the `Test::Class::Moose::Reporting` object. Useful if you want to do
your own reporting and not rely on the default output provided with the
`statistics` boolean option.

### `this_class`

    my $class = $test->this_class;

Returns the name for this class. Useful if you rebless an object (such as
applying a role at runtime) and lose the original class name.

## METHODS

### `get_test_classes`

You may override this in a subclass. Currently returns a sorted list of all
loaded classes that inherit directly or indirectly through
`Test::Class::Moose`

### `get_test_methods`

You may override this in a subclass. Currently returns all methods in a test
class that start with `test_` (except for the test control methods).

Please note that the behavior for `include` and `exclude` is also contained
in this method. If you override it, you will need to account for those
yourself.

### `runtests`

If you really, really want to change how this module works, you can override
the `runtests` method. We don't recommend it.

### `import`

Sadly, we have an `import` method. This is used to automatically provide you
with all of the `Test::Most` behavior.

# SAMPLE TAP OUTPUT

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

# REPORTING

Reporting features are subject to change. Currently the timing relies on
[Benchmark](http://search.cpan.org/perldoc?Benchmark) and your author's not quite happy about that.

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
                diag "Run time for $method_name: ".$method->duration;
            }
        };
        diag "Run time for $class_name: ".$class->duration;
    }
    diag "Number of test classes: " . $reporting->num_test_classes;
    diag "Number of test methods: " . $reporting->num_test_methods;
    diag "Number of tests:        " . $reporting->num_tests;

    done_testing;

# TODO

- Load classes

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

- Pass class/method names to test control methods
- Make it easy to skip an entire class

# AUTHOR

Curtis "Ovid" Poe, `<ovid at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-test-class-moose at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Class-Moose](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Class-Moose).  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Class::Moose

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

[http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Class-Moose](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Class-Moose)

- AnnoCPAN: Annotated CPAN documentation

[http://annocpan.org/dist/Test-Class-Moose](http://annocpan.org/dist/Test-Class-Moose)

- CPAN Ratings

[http://cpanratings.perl.org/d/Test-Class-Moose](http://cpanratings.perl.org/d/Test-Class-Moose)

- Search CPAN

[http://search.cpan.org/dist/Test-Class-Moose/](http://search.cpan.org/dist/Test-Class-Moose/)

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

Copyright 2012 Curtis "Ovid" Poe.

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.