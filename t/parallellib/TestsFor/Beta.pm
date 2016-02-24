package TestsFor::Beta;

use Test::Class::Moose;

use Test2::Tools::Compare qw( array call end event T );

sub test_beta_first {
    my $test = shift;
    ok 1;
    ok 2;
}

sub test_second {
    my $test = shift;
    ok 1;
    ok 2;
}

sub expected_test_events {
    event Subtest => sub {
        call name      => 'TestsFor::Beta';
        call pass      => T();
        call subevents => array {
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
            end();
        };
    };
}

1
