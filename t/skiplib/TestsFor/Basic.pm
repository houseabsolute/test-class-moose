package TestsFor::Basic;
use Test::Class::Moose;

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

1;
