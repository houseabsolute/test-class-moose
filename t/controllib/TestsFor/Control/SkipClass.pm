package TestsFor::Control::SkipClass;

use strict;
use warnings;
use namespace::autoclean;

use Test::Class::Moose bare => 1;

use Test2::Tools::Basic qw( diag ok );
use Test2::Tools::Compare qw( array call end event filter_items F is T );

sub test_startup {
    my $self = shift;
    $self->test_skip('skip all methods');
}

sub test_shutdown {
    diag('in shutdown');
}

# This should never be called
sub test_method {
    ok(1);
}

sub run_control_methods_on_skip {1}

sub expected_test_events {
    event Subtest => sub {
        call name      => 'TestsFor::Control::SkipClass';
        call pass      => T();
        call subevents => array {
            filter_items {
                grep {
                         !$_->isa('Test2::AsyncSubtest::Event::Attach')
                      && !$_->isa('Test2::AsyncSubtest::Event::Detach')
                } @_;
            };
            event Diag => sub {
                call message => 'in shutdown';
            };
            event Plan => sub {
                call directive => 'SKIP';
                call reason    => 'skip all methods';
                call max       => 0;
            };
            end();
        };
    };
}

sub expected_report {
    return (
        'TestsFor::Control::SkipClass' => {
            is_skipped => F(),
            passed     => T(),
            instances  => {
                'TestsFor::Control::SkipClass' => {
                    is_skipped => T(),
                    passed     => T(),
                },
            },
        },
    );
}

1;

