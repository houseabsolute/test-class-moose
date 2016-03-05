package TestsFor::SkipSomeMethods;

use Test::Class::Moose bare => 1;

use Test2::Tools::Basic qw( ok );
use Test2::Tools::Compare qw( array call end event is T );

sub test_setup {
    my $test = shift;
    if ( 'test_me' eq $test->test_report->current_method->name ) {
        $test->test_skip('only methods listed as skipped should be skipped');
    }
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
    my $include_async = $_[1];

    event Subtest => sub {
        call name      => 'TestsFor::SkipSomeMethods';
        call pass      => T();
        call subevents => array {
            event '+Test2::AsyncSubtest::Event::Attach'
              if $include_async;
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
            event '+Test2::AsyncSubtest::Event::Detach'
              if $include_async;
            end();
        };
    };
}

1;
