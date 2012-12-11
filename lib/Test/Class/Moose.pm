package Test::Class::Moose;

use Moose;
use Carp;
use Test::Builder;
use Data::Dumper;
use namespace::autoclean;

sub import {
    my ($class,%arg_for) = @_;
    my $caller = caller;

    eval <<"END";
package $caller;
use Test::Most;
use Moose;
END
    croak($@) if $@;
    if ( my $parent = delete $arg_for{parent} ) {
        my @parents = 'ARRAY' eq ref $parent ? @$parent : $parent;
        $caller->meta->superclasses(@parents);
    }
    else {
        $caller->meta->superclasses(__PACKAGE__);
    }
}

sub runtests {
    my $self  = shift;

    my @classes = $self->get_classes;
    my $builder = Test::Builder->new;

    foreach my $class (@classes) {
        my $tests = $class->new;
        $class->test_startup;
        foreach my $test ($self->get_tests($class)) {
            $class->test_setup;
            $builder->subtest( $test, sub { $tests->$test } );
            $class->test_teardown;
        }
        $class->test_shutdown;
    }       
}

sub get_classes {
    my $self        = shift;
    my %metaclasses = Class::MOP::get_all_metaclasses();
    my @classes;
    while ( my ( $class, $metaclass ) = each %metaclasses ) {
        next unless $metaclass->can('superclasses');
        push @classes => $class
          if grep { $_ eq __PACKAGE__ } $metaclass->superclasses;
    }
    return @classes;
}

sub get_tests {
    my ( $self, $test_class ) = @_;
    return grep { /^test_/ } $test_class->meta->get_method_list;
}

sub test_startup  {}
sub test_setup    {}
sub test_teardown {}
sub test_shutdown {}

__PACKAGE__->meta->make_immutable;

1;
