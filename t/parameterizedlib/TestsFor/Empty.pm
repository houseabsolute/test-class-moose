package TestsFor::Empty;

use Test::Class::Moose bare => 1;

use Test2::Tools::Basic qw( fail );
use Test2::Tools::Compare qw( array call end event filter_items T );

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

sub expected_test_events {
    event Subtest => sub {
        call name      => 'TestsFor::Empty';
        call pass      => T();
        call subevents => array {
            filter_items {
                grep {
                         !$_->isa('Test2::AsyncSubtest::Event::Attach')
                      && !$_->isa('Test2::AsyncSubtest::Event::Detach')
                } @_;
            };
            event Plan => sub {
                call directive => 'SKIP';
                call reason =>
                  q{Skipping 'TestsFor::Empty': no test instances found};
                call max => 0;
            };
            end();
        };
    };
}

1;
