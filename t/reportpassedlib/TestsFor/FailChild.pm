package TestsFor::FailChild;
use Test::Class::Moose extends => 'Fail';

sub test_a_good {
    ok 1;
}

sub test_a_bad {
    ok 1;
}

sub test_b_good {
    ok 1;
}

sub test_b_bad {
    ok 1;
}

sub test_another { ok 1 }

1;
