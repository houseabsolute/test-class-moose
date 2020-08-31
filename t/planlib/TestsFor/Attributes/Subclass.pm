package TestsFor::Attributes::Subclass;

use Test::Class::Moose extends => 'TestsFor::Attributes', bare => 1;

use Test2::Tools::Basic qw( pass );
use Test2::Tools::Compare qw( array call end event T );

sub test_just_one_test : Test {
    pass 'We should only have a single test';
}

sub test_more_than_one_test : Tests(1) {
    my $test = shift;
    $test->next::method;
    pass 'Overriding and calling parent';
}

sub test_with_attribute_but_no_plan : Tests(3) {
    pass "Overriding and not calling parent: $_" for 1 .. 3;
}

sub this_is_a_test_method_because_of_the_attribute : Tests {
    my $test = shift;
    $test->next::method;
    pass
      "Overriding and calling parent, but we don't have a plan and parent does: $_"
      for 1 .. 2;
}

sub expected_test_events {
    event Note => sub {
        call message => 'Subtest: TestsFor::Attributes::Subclass';
    };
    event Subtest => sub {
        call name      => 'Subtest: TestsFor::Attributes::Subclass';
        call pass      => T();
        call subevents => array {
            event Plan => sub {
                call max => 4;
            };
            event Note => sub {
                call message => 'Subtest: test_just_one_test';
            };
            event Subtest => sub {
                call name      => 'Subtest: test_just_one_test';
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
                call message => 'Subtest: test_more_than_one_test';
            };
            event Subtest => sub {
                call name      => 'Subtest: test_more_than_one_test';
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
                    event Ok => sub {
                        call pass => T();
                        call name => 'Overriding and calling parent';
                    };
                    event Plan => sub {
                        call max => 3;
                    };
                    end();
                };
            };
            event Note => sub {
                call message => 'Subtest: test_with_attribute_but_no_plan';
            };
            event Subtest => sub {
                call name      => 'Subtest: test_with_attribute_but_no_plan';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call pass => T();
                        call name => 'Overriding and not calling parent: 1';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => 'Overriding and not calling parent: 2';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => 'Overriding and not calling parent: 3';
                    };
                    event Plan => sub {
                        call max => 3;
                    };
                    end();
                };
            };
            event Note => sub {
                call message =>
                  'Subtest: this_is_a_test_method_because_of_the_attribute';
            };
            event Subtest => sub {
                call name =>
                  'Subtest: this_is_a_test_method_because_of_the_attribute';
                call pass      => T();
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
                    event Ok => sub {
                        call pass => T();
                        call name =>
                          q{Overriding and calling parent, but we don't have a plan and parent does: 1};
                    };
                    event Ok => sub {
                        call pass => T();
                        call name =>
                          q{Overriding and calling parent, but we don't have a plan and parent does: 2};
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

1;
