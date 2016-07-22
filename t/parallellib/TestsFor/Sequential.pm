package TestsFor::Sequential;

use Test::Class::Moose bare => 1;

use Test2::Tools::Basic qw( ok );
use Test2::Tools::Compare qw( array call end event filter_items F is T );

sub test_sequential_first : Tags(noparallel) {
    ok 1;
}

sub test_sequential_second {
    ok 1;
}

sub expected_test_events {
    event Subtest => sub {
        call name      => 'TestsFor::Sequential';
        call pass      => T();
        call subevents => array {
            event Plan => sub {
                call max => 2;
            };
            event Subtest => sub {
                call name      => 'test_sequential_first';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call name => undef;
                        call pass => T();
                    };
                    event Plan => sub {
                        call max => 1;
                    };
                    end();
                };
            };
            event Subtest => sub {
                call name      => 'test_sequential_second';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call name => undef;
                        call pass => T();
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
}

sub expected_report {
    return (
        'TestsFor::Sequential' => {
            is_skipped => F(),
            passed     => T(),
            instances  => {
                'TestsFor::Sequential' => {
                    is_skipped => F(),
                    passed     => T(),
                    methods    => {
                        test_sequential_first => {
                            is_skipped    => F(),
                            passed        => T(),
                            num_tests_run => 1,
                            tests_planned => 1,
                        },
                        test_sequential_second => {
                            is_skipped    => F(),
                            passed        => T(),
                            num_tests_run => 1,
                            tests_planned => 1,
                        },
                    },
                },
            },
        },
    );
}

1
