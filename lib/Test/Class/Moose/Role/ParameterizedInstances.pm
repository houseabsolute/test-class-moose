package Test::Class::Moose::Role::ParameterizedInstances;

# ABSTRACT: run tests against multiple instances of a test class

use strict;
use warnings;
use namespace::autoclean;

use 5.10.0;

our $VERSION = '0.71';

use Moose::Role;

requires '_constructor_parameter_sets';

sub _tcm_make_test_class_instances {
    my $class     = shift;
    my %base_args = @_;

    my %sets = $class->_constructor_parameter_sets;
    return map { $_ => $class->new( %{ $sets{$_} }, %base_args ) }
      keys %sets;
}

1;

__END__
