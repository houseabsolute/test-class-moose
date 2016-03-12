package TestsFor::SkipAll;

use Test::Class::Moose bare => 1;

use Test2::Tools::Basic qw( ok );
use Test2::Tools::Compare qw( array call end event filter_items F is T );

sub test_startup {
    my $test = shift;
    $test->test_skip('all methods should be skipped');
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

sub expected_test_events {
    event Subtest => sub {
        call name      => 'TestsFor::SkipAll';
        call pass      => T();
        call subevents => array {
            filter_items {
                grep {
                         !$_->isa('Test2::AsyncSubtest::Event::Attach')
                      && !$_->isa('Test2::AsyncSubtest::Event::Detach')
                } @_;
            };
            event Plan => sub {
                call directive => 'SKIP';
                call reason    => 'all methods should be skipped';
                call max       => 0;
            };
            end();
        };
    };
}

sub expected_report {
    return (
        'TestsFor::SkipAll' => {
            is_skipped => F(),
            passed     => T(),
            instances  => {
                'TestsFor::SkipAll' => {
                    is_skipped => T(),
                    passed     => T(),
                },
            },
        },
    );
}

1;
