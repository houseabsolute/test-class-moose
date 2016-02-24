package TestsFor::Alpha;

use Test::Class::Moose;

use Test2::Tools::Compare qw( array call end event T );

sub test_alpha_first {
    my $test = shift;
    ok 1;
    ok 2;
}

sub test_second {
    my $test = shift;
    $test->test_report->plan(1);
    ok 1, 'make sure plans work';
}

sub expected_test_events {
    event Subtest => sub {
        call name      => 'TestsFor::Alpha';
        call pass      => T();
        call subevents => array {
            event Plan => sub {
                call max => 2;
            };
            event Subtest => sub {
                call name      => 'test_alpha_first';
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
                        call name => 'make sure plans work';
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

1;
