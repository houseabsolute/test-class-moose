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
    $self->this_class($self->meta->name);
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
    Test::Most::explain("$test_class->$test_method()"),
    $builder->subtest(
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
                            $num_tests += $self->$run_test_method( $test_instance,
                                $test_method );
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

    state $is_test_control_method =
      { map { ; "test_$_" => 1 } qw/startup setup teardown shutdown/ };

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

This is a tiny proof of concept for writing Test::Class-style tests with
Moose.
