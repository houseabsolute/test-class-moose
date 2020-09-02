package TestsFor::Attributes;

use Test::Class::Moose bare => 1;

use Test2::Tools::Basic qw( pass );
use Test2::Tools::Compare qw( array call end event T );

sub test_just_one_test : Test {
    pass 'We should only have a single test';
}

sub test_more_than_one_test : Tests(2) {
    pass 'This is our first test';
    pass 'This is our second test';
}

sub test_with_attribute_but_no_plan : Tests {
    pass "This is test number $_" for 1 .. 5;
}

sub this_is_a_test_method_because_of_the_attribute : Tests(3) {
    pass "These tests work: $_" for 1 .. 3;
}

sub expected_test_events {
    event Note => sub {
        call message => 'TestsFor::Attributes';
    };
    event Subtest => sub {
        call name      => 'TestsFor::Attributes';
        call pass      => T();
        call subevents => array {
            event Plan => sub {
                call max => 4;
            };
            event Note => sub {
                call message => 'test_just_one_test';
            };
            event Subtest => sub {
                call name      => 'test_just_one_test';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call pass => T();
                        call name => 'We should only have a single test';
                    };
                    event Plan => sub {
                        call max => 1;
                    };
                    end();
                };
            };
            event Note => sub {
                call message => 'test_more_than_one_test';
            };
            event Subtest => sub {
                call name      => 'test_more_than_one_test';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call pass => T();
                        call name => 'This is our first test';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => 'This is our second test';
                    };
                    event Plan => sub {
                        call max => 2;
                    };
                    end();
                };
            };
            event Note => sub {
                call message => 'test_with_attribute_but_no_plan';
            };
            event Subtest => sub {
                call name      => 'test_with_attribute_but_no_plan';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call pass => T();
                        call name => 'This is test number 1';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => 'This is test number 2';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => 'This is test number 3';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => 'This is test number 4';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => 'This is test number 5';
                    };
                    event Plan => sub {
                        call max => 5;
                    };
                    end();
                };
            };
            event Note => sub {
                call message =>
                  'this_is_a_test_method_because_of_the_attribute';
            };
            event Subtest => sub {
                call name => 'this_is_a_test_method_because_of_the_attribute';
                call pass => T();
                call subevents => array {
                    event Ok => sub {
                        call pass => T();
                        call name => 'These tests work: 1';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => 'These tests work: 2';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => 'These tests work: 3';
                    };
                    event Plan => sub {
                        call max => 3;
                    };
                    end();
                };
            };
            end();
        };
    };
}

1;
