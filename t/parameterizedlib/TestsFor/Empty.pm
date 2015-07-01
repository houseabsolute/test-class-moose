package TestsFor::Empty;
use Test::Class::Moose;
with 'Test::Class::Moose::Role::ParameterizedInstances';

sub _constructor_parameter_sets {
    # dynamically decided that there is nothing to do (e.g., because
    # I'm being called in the context of an abstract base class)
    return ();
}

sub test_one_set {
    my $self = shift;
    fail('this test should never be called');
}

1;
