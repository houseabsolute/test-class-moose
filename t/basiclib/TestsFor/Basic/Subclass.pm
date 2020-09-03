package TestsFor::Basic::Subclass;

use Test::Class::Moose extends => 'TestsFor::Basic', bare => 1;

use Test2::Tools::Basic qw( fail ok pass );
use Test2::Tools::Compare qw( array call end event filter_items F is T );

sub test_me {
    my $test  = shift;
    my $class = $test->test_class;
    ok 1, "I overrode my parent! ($class)";
}

before 'test_this_baby' => sub {
    my $test  = shift;
    my $class = $test->test_class;
    pass "This should run before my parent method ($class)";
};

sub this_should_not_run {
    fail "We should never see this test";
}

sub test_this_should_be_run {
    for ( 1 .. 5 ) {
        pass "This is test number $_ in this method";
    }
}

sub expected_test_events {
    event Note => sub {
        call message => 'TestsFor::Basic::Subclass';
    };
    event Subtest => sub {
        call name      => 'TestsFor::Basic::Subclass';
        call pass      => T();
        call subevents => array {
            filter_items {
                grep {
                         !$_->isa('Test2::AsyncSubtest::Event::Attach')
                      && !$_->isa('Test2::AsyncSubtest::Event::Detach')
                } @_;
            };
            event Plan => sub {
                call max => 5;
            };
            event Note => sub {
                call message => 'test_me';
            };
            event Subtest => sub {
                call name      => 'test_me';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call pass => T();
                        call name =>
                          'I overrode my parent! (TestsFor::Basic::Subclass)';
                    };
                    event Plan => sub {
                        call max => 1;
                    };
                    end();
                };
            };
            event Note => sub {
                call message => 'test_my_instance_name';
            };
            event Subtest => sub {
                call name      => 'test_my_instance_name';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call pass => T();
                        call name => 'test_instance_name matches class name';
                    };
                    event Plan => sub {
                        call max => 1;
                    };
                    end();
                };
            };
            event Note => sub {
                call message => 'test_reporting';
            };
            event Subtest => sub {
                call name      => 'test_reporting';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call pass => T();
                        call name =>
                          'current_instance() should report the correct class name';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name =>
                          '... and we should also be able to get the current method name';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name =>
                          'test_setup() should know our current class name';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => '... and our current method name';
                    };
                    event Plan => sub {
                        call max => 4;
                    };
                    end();
                };
            };
            event Note => sub {
                call message => 'test_this_baby';
            };
            event Subtest => sub {
                call name      => 'test_this_baby';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call pass => T();
                        call name =>
                          'This should run before my parent method (TestsFor::Basic::Subclass)';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => 'whee! (TestsFor::Basic::Subclass)';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name =>
                          'test_setup() should know our current class name';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => '... and our current method name';
                    };
                    event Plan => sub {
                        call max => 4;
                    };
                    end();
                };
            };
            event Note => sub {
                call message => 'test_this_should_be_run';
            };
            event Subtest => sub {
                call name      => 'test_this_should_be_run';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call pass => T();
                        call name => 'This is test number 1 in this method';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => 'This is test number 2 in this method';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => 'This is test number 3 in this method';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => 'This is test number 4 in this method';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => 'This is test number 5 in this method';
                    };
                    event Plan => sub {
                        call max => 5;
                    };
                    end();
                };
            };
            end();
        };
    };
}

sub expected_parallel_test_events {
    event Subtest => sub {
        call name      => 'TestsFor::Basic::Subclass';
        call pass      => T();
        call subevents => array {
            filter_items {
                grep {
                         !$_->isa('Test2::AsyncSubtest::Event::Attach')
                      && !$_->isa('Test2::AsyncSubtest::Event::Detach')
                } @_;
            };
            event Plan => sub {
                call max => 5;
            };
            event Subtest => sub {
                call name      => 'test_me';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call pass => T();
                        call name =>
                          'I overrode my parent! (TestsFor::Basic::Subclass)';
                    };
                    event Plan => sub {
                        call max => 1;
                    };
                    end();
                };
            };
            event Subtest => sub {
                call name      => 'test_my_instance_name';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call pass => T();
                        call name => 'test_instance_name matches class name';
                    };
                    event Plan => sub {
                        call max => 1;
                    };
                    end();
                };
            };
            event Subtest => sub {
                call name      => 'test_reporting';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call pass => T();
                        call name =>
                          'current_instance() should report the correct class name';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name =>
                          '... and we should also be able to get the current method name';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name =>
                          'test_setup() should know our current class name';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => '... and our current method name';
                    };
                    event Plan => sub {
                        call max => 4;
                    };
                    end();
                };
            };
            event Subtest => sub {
                call name      => 'test_this_baby';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call pass => T();
                        call name =>
                          'This should run before my parent method (TestsFor::Basic::Subclass)';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => 'whee! (TestsFor::Basic::Subclass)';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name =>
                          'test_setup() should know our current class name';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => '... and our current method name';
                    };
                    event Plan => sub {
                        call max => 4;
                    };
                    end();
                };
            };
            event Subtest => sub {
                call name      => 'test_this_should_be_run';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call pass => T();
                        call name => 'This is test number 1 in this method';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => 'This is test number 2 in this method';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => 'This is test number 3 in this method';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => 'This is test number 4 in this method';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => 'This is test number 5 in this method';
                    };
                    event Plan => sub {
                        call max => 5;
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
        'TestsFor::Basic::Subclass' => {
            is_skipped => F(),
            passed     => T(),
            instances  => {
                'TestsFor::Basic::Subclass' => {
                    is_skipped => F(),
                    passed     => T(),
                    methods    => {
                        test_me => {
                            is_skipped    => F(),
                            passed        => T(),
                            num_tests_run => 1,
                            tests_planned => 1,
                        },
                        test_my_instance_name => {
                            is_skipped    => F(),
                            passed        => T(),
                            num_tests_run => 1,
                            tests_planned => 1,
                        },
                        test_reporting => {
                            is_skipped    => F(),
                            passed        => T(),
                            num_tests_run => 4,
                            tests_planned => 4,
                        },
                        test_this_baby => {
                            is_skipped    => F(),
                            passed        => T(),
                            num_tests_run => 4,
                            tests_planned => 4,
                        },
                        test_this_should_be_run => {
                            is_skipped    => F(),
                            passed        => T(),
                            num_tests_run => 5,
                            tests_planned => 5,
                        },
                    },
                },
            },
        },
    );
}

1;
