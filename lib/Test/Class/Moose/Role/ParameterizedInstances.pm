package Test::Class::Moose::Role::ParameterizedInstances;

# ABSTRACT: run tests against multiple instances of a test class

use Moose::Role;

requires '_tcm_constructor_parameter_sets';

sub _tcm_make_test_class_instances {
    my ( $class, $args ) = @_;

    my %base_args = %{$args};

    my %sets = $class->_tcm_constructor_parameter_sets;
    return map { $_ => $class->new( %{ $sets{$_} }, %base_args ) }
        keys %sets;
}

1;

__END__
