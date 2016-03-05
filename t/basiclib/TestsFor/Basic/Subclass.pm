package TestsFor::Basic::Subclass;

use Test::Class::Moose extends => 'TestsFor::Basic', bare => 1;

use Test2::Tools::Basic qw( fail ok pass );
use Test2::Tools::Compare qw( array call end event is T );

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
    my $test = shift;
    fail "We should never see this test";
}

sub test_this_should_be_run {
    for ( 1 .. 5 ) {
        pass "This is test number $_ in this method";
    }
}

sub expected_test_events {
    my $include_async = $_[1];

    event Subtest => sub {
        call name      => 'TestsFor::Basic::Subclass';
        call pass      => T();
        call subevents => array {
            event '+Test2::AsyncSubtest::Event::Attach'
                if $include_async;
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
            event '+Test2::AsyncSubtest::Event::Detach'
                if $include_async;
            end();
        };
    };
}

1;
