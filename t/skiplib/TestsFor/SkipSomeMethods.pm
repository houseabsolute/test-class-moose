package TestsFor::SkipSomeMethods;

use Test::Class::Moose;

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

1;
