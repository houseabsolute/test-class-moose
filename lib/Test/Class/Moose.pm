package Test::Class::Moose;

use 5.10.0;
use Moose;
use Carp;
use Test::Builder;
use Benchmark qw(timediff timestr);
use namespace::autoclean;

has 'show_timing' => ( 
    is => 'ro', 
    isa => 'Bool',
);
has 'builder' => (
    is      => 'ro',
    isa     => 'Test::Builder',
    default => sub {
        Test::Builder->new;
    },
);

sub import {
    my ($class,%arg_for) = @_;
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

my $time_this = sub {
    my ( $self, $name, $sub ) = @_;
    my $start = Benchmark->new;
    $sub->();
    if ( $self->show_timing ) {
        my $time = timestr(timediff(Benchmark->new,$start));
        $self->builder->diag("$name: $time");
    }
};

sub runtests {
    my $self  = shift;

    my @classes = $self->get_test_classes;
    my $builder = $self->builder;

    foreach my $class (@classes) {
        $self->$time_this(
            "Runtime for $class",
            sub {
                my $tests = $class->new;
                $class->test_startup;
                foreach my $test ( $self->get_test_methods($class) ) {
                    $self->$time_this(
                        "Runtime per test $class\::$test",
                        sub {
                            $class->test_setup;
                            $builder->subtest( $test, sub { $tests->$test } );
                            $class->test_teardown;
                        }
                    );
                }
                $class->test_shutdown;
            }
        );
    }       
}

sub get_test_classes {
    my $self        = shift;
    my %metaclasses = Class::MOP::get_all_metaclasses();
    my @classes;
    while ( my ( $class, $metaclass ) = each %metaclasses ) {
        next unless $metaclass->can('superclasses');
        $DB::single = $class eq 'main';
        $DB::single = $class eq 'TestsFor::Basic::Subclass';
        push @classes => $class
          if grep { $_ eq __PACKAGE__ } $metaclass->linearized_isa;
    }

    # eventually we'll want to control the test class order
    return @classes;
}

sub get_test_methods {
    my ( $self, $test_class ) = @_;

    state $is_test_control_method =
      { map {; "test_$_" => 1 } qw/startup setup teardown shutdown/ };

    # eventuall we'll want to control the test method order
    return
      sort grep { /^test_/ and not $is_test_control_method->{$_} }
      $test_class->meta->get_method_list;
}

sub test_startup  {}
sub test_setup    {}
sub test_teardown {}
sub test_shutdown {}

__PACKAGE__->meta->make_immutable;

1;
