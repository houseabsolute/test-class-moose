package TestsFor::Parameterized;

use Test::Class::Moose;

with 'Test::Class::Moose::Role::ParameterizedInstances';

has 'foo' => ( is => 'ro' );

sub _constructor_parameter_sets {
    return (
        __PACKAGE__ . ' with foo = 42' => { foo => 42 },
        __PACKAGE__ . ' with foo = 84' => { foo => 84 },
    );
}

sub test_process_name {
    my $self    = shift;
    my $package = __PACKAGE__;
    my $foo     = $self->foo;
    like(
        $0, qr/$package with foo = $foo/,
        '$0 contains test instance name'
    );
}

1;
