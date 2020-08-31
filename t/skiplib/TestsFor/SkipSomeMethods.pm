package TestsFor::SkipSomeMethods;

use Test::Class::Moose bare => 1;

use Test2::Tools::Basic qw( diag ok );
use Test2::Tools::Compare qw( array call end event filter_items F is T );

sub test_setup {
    my $test = shift;
    if ( 'test_me' eq $test->test_report->current_method->name ) {
        $test->test_skip('only methods listed as skipped should be skipped');
    }
}

# This should not be called when a method is skipped
sub test_teardown {
    diag('in teardown');
}

sub test_me {
    my $test  = shift;
    my $class = ref $test;
    ok 1, "test_me() ran ($class)";
    ok 2, "this is another test ($class)";
}

sub test_this_baby {
    my $test  = shift;
    my $class = ref $test;
    is 2, 2, "whee! ($class)";
}

sub test_again { ok 1, 'in test_again' }

sub expected_test_events {
    event Note => sub {
        call message => 'Subtest: TestsFor::SkipSomeMethods';
    };
    event Subtest => sub {
        call name      => 'Subtest: TestsFor::SkipSomeMethods';
        call pass      => T();
        call subevents => array {
            filter_items {
                grep {
                         !$_->isa('Test2::AsyncSubtest::Event::Attach')
                      && !$_->isa('Test2::AsyncSubtest::Event::Detach')
                } @_;
            };
            event Plan => sub {
                call max => 3;
            };
            event Note => sub {
                call message => 'Subtest: test_again';
            };
            event Subtest => sub {
                call name      => 'Subtest: test_again';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call name => 'in test_again';
                        call pass => T();
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
            event Note => sub {
                call message => 'Subtest: test_me';
            };
            event Subtest => sub {
                call name      => 'Subtest: test_me';
                call pass      => T();
                call subevents => array {
                    event Plan => sub {
                        call directive => 'SKIP';
                        call reason =>
                          'only methods listed as skipped should be skipped';
                        call max => 0;
                    };
                    end();
                };
            };
            event Note => sub {
                call message => 'Subtest: test_this_baby';
            };
            event Subtest => sub {
                call name      => 'Subtest: test_this_baby';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call name => 'whee! (TestsFor::SkipSomeMethods)';
                        call pass => T();
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
            end();
        };
    };
}

sub expected_parallel_test_events {
    event Subtest => sub {
        call name      => 'TestsFor::SkipSomeMethods';
        call pass      => T();
        call subevents => array {
            filter_items {
                grep {
                         !$_->isa('Test2::AsyncSubtest::Event::Attach')
                      && !$_->isa('Test2::AsyncSubtest::Event::Detach')
                } @_;
            };
            event Plan => sub {
                call max => 3;
            };
            event Subtest => sub {
                call name      => 'test_again';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call name => 'in test_again';
                        call pass => T();
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
                call name      => 'test_me';
                call pass      => T();
                call subevents => array {
                    event Plan => sub {
                        call directive => 'SKIP';
                        call reason =>
                          'only methods listed as skipped should be skipped';
                        call max => 0;
                    };
                    end();
                };
            };
            event Subtest => sub {
                call name      => 'test_this_baby';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call name => 'whee! (TestsFor::SkipSomeMethods)';
                        call pass => T();
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
            end();
        };
    };
}

sub expected_report {
    return (
        'TestsFor::SkipSomeMethods' => {
            is_skipped => F(),
            passed     => T(),
            instances  => {
                'TestsFor::SkipSomeMethods' => {
                    is_skipped => F(),
                    passed     => T(),
                    methods    => {
                        test_again => {
                            is_skipped    => F(),
                            passed        => T(),
                            num_tests_run => 1,
                            tests_planned => 1,
                        },
                        test_me => {
                            is_skipped    => T(),
                            passed        => T(),
                            num_tests_run => 0,
                        },
                        test_this_baby => {
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

1;
