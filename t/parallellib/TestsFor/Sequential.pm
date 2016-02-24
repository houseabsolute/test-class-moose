package TestsFor::Sequential;

use Test::Class::Moose;

use Test2::Tools::Compare qw( array call end event T );

sub test_sequential_first : Tags(noparallel) {
    my $test = shift;
    ok 1;
}

sub test_sequential_second {
    my $test = shift;
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

1
