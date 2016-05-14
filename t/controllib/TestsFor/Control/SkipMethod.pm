package TestsFor::Control::SkipMethod;

use Test::Class::Moose bare => 1;

use Test2::Tools::Basic qw( diag ok );
use Test2::Tools::Compare qw( array call end event filter_items F is T );

sub test_setup {
    my $self = shift;
    $self->test_skip('skip a method')
      if $self->test_report->current_method->name eq 'test_will_skip';
}

sub test_teardown {
    diag('in teardown');
}

# Will be called
sub test_method {
    ok( 1, 'test_method' );
}

# Will be skipped
sub test_will_skip {
    ok( 0, 'test_will_skip' );
}

sub run_control_methods_on_skip {1}

sub expected_test_events {
    event Subtest => sub {
        call name      => 'TestsFor::Control::SkipMethod';
        call pass      => T();
        call subevents => array {
            filter_items {
                grep {
                         !$_->isa('Test2::AsyncSubtest::Event::Attach')
                      && !$_->isa('Test2::AsyncSubtest::Event::Detach')
                } @_;
            };
            event Plan => sub {
                call max => 2;
            };
            event Subtest => sub {
                call name      => 'test_method';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call pass => T();
                        call name => 'test_method';
                    };
                    event Plan => sub {
                        call max => 1;
                    };
                    end();
                };
            };
            event Diag => sub {
                call message => 'in teardown';
            };
            event Subtest => sub {
                call name      => 'test_will_skip';
                call pass      => T();
                call subevents => array {
                    event Plan => sub {
                        call directive => 'SKIP';
                        call reason    => 'skip a method';
                        call max       => 0;
                    };
                    end();
                };
            };
            event Diag => sub {
                call message => 'in teardown';
            };
            end();
        };
    };
}

sub expected_report {
    return (
        'TestsFor::Control::SkipMethod' => {
            is_skipped => F(),
            passed     => T(),
            instances  => {
                'TestsFor::Control::SkipMethod' => {
                    is_skipped => F(),
                    passed     => T(),
                    methods    => {
                        test_method => {
                            is_skipped    => F(),
                            passed        => T(),
                            num_tests_run => 1,
                            tests_planned => 1,
                        },
                        test_will_skip => {
                            is_skipped    => T(),
                            passed        => T(),
                            num_tests_run => 0,
                        },
                    },
                },
            },
        },
    );
}

1;
