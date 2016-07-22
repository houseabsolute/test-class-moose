package TestsFor::Beta;

use Test::Class::Moose bare => 1;

use Test2::Tools::Basic qw( ok );
use Test2::Tools::Compare qw( array call end event F is T );

sub test_beta_first {
    ok 1;
    ok 2;
}

sub test_second {
    ok 1;
    ok 2;
}

sub expected_test_events {
    event Subtest => sub {
        call name      => 'TestsFor::Beta';
        call pass      => T();
        call subevents => array {
            event '+Test2::AsyncSubtest::Event::Attach';
            event Plan => sub {
                call max => 2;
            };
            event Subtest => sub {
                call name      => 'test_beta_first';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call name => undef;
                        call pass => T();
                    };
                    event Ok => sub {
                        call name => undef;
                        call pass => T();
                    };
                    event Plan => sub {
                        call max => 2;
                    };
                    end();
                };
            };
            event Subtest => sub {
                call name      => 'test_second';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call name => undef;
                        call pass => T();
                    };
                    event Ok => sub {
                        call name => undef;
                        call pass => T();
                    };
                    event Plan => sub {
                        call max => 2;
                    };
                    end();
                };
            };
            event '+Test2::AsyncSubtest::Event::Detach';
            end();
        };
    };
}

sub expected_report {
    return (
        'TestsFor::Beta' => {
            is_skipped => F(),
            passed     => T(),
            instances  => {
                'TestsFor::Beta' => {
                    is_skipped => F(),
                    passed     => T(),
                    methods    => {
                        test_beta_first => {
                            is_skipped    => F(),
                            passed        => T(),
                            num_tests_run => 2,
                            tests_planned => 2,
                        },
                        test_second => {
                            is_skipped    => F(),
                            passed        => T(),
                            num_tests_run => 2,
                            tests_planned => 2,
                        },
                    },
                },
            },
        },
    );
}

1
