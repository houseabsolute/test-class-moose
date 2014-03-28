package TestsFor::Parameterized;
use Test::Class::Moose;
with 'Test::Class::Moose::Role::ParameterizedInstances';

has [ 'foo', 'bar' ] => ( is => 'ro' );

sub _tcm_constructor_parameter_sets {
    return (
        { foo => 42 },
        { bar => 42 },
    );
}

sub _tcm_instance_name {
    my $self = shift;
    return $self->foo ? __PACKAGE__ . ' with foo' : __PACKAGE__ . ' with bar';
}

sub test_one_set {
    my $self = shift;

    if ( $self->foo ) {
        is( $self->foo, 42, 'ran a test where foo is 42' );
    }
    elsif ( $self->bar ) {
        is( $self->bar, 42, 'ran a test where bar is 42' );
    }
    else {
        fail('ran a test where neither foo nor bar are set - this should be impossible');
    }
}

1;
