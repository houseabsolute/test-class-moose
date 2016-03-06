package TestsFor::Parameterized;

use Test::Class::Moose bare => 1;

use Test2::Tools::Basic qw( fail );
use Test2::Tools::Compare qw( array call end event is T );

with 'Test::Class::Moose::Role::ParameterizedInstances';

has [ 'foo', 'bar' ] => ( is => 'ro' );

sub _constructor_parameter_sets {
    return (
        __PACKAGE__ . ' with foo' => { foo => 42 },
        __PACKAGE__ . ' with bar' => { bar => 42 },
    );
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
        fail(
            'ran a test where neither foo nor bar are set - this should be impossible'
        );
    }
}

sub expected_test_events {
    my $include_async = $_[1];

    event Subtest => sub {
        call name      => 'TestsFor::Parameterized';
        call pass      => T();
        call subevents => array {
            event '+Test2::AsyncSubtest::Event::Attach'
              if $include_async;
            event Plan => sub {
                call max => 2;
            };
            event Subtest => sub {
                call name      => 'TestsFor::Parameterized with bar';
                call pass      => T();
                call subevents => array {
                    event Plan => sub {
                        call max => 1;
                    };
                    event Subtest => sub {
                        call name      => 'test_one_set';
                        call pass      => T();
                        call subevents => array {
                            event Ok => sub {
                                call pass => T();
                                call name => 'ran a test where bar is 42';
                            };
                            event Plan => sub {
                                call max => 1;
                            };
                            end();
                        };
                    };
                    end();
                };
            };
            event Subtest => sub {
                call name      => 'TestsFor::Parameterized with foo';
                call pass      => T();
                call subevents => array {
                    event Plan => sub {
                        call max => 1;
                    };
                    event Subtest => sub {
                        call name      => 'test_one_set';
                        call pass      => T();
                        call subevents => array {
                            event Ok => sub {
                                call pass => T();
                                call name => 'ran a test where foo is 42';
                            };
                            event Plan => sub {
                                call max => 1;
                            };
                            end();
                        };
                    };
                    end();
                };
            };
            event '+Test2::AsyncSubtest::Event::Detach'
              if $include_async;
            end();
        };
    };
}

1;
