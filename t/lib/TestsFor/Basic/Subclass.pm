package TestsFor::Basic::Subclass;
use Test::Class::Moose extends => 'TestsFor::Basic';

sub test_me {
    my $test  = shift;
    my $class = $test->test_class;
    ok 1, "I overrode my parent! ($class)";
}

before 'test_this_baby' => sub {
    my $test  = shift;
    my $class = $test->test_class;
    pass "This should run before my parent method ($class)";
};

sub this_should_not_run {
    my $test = shift;
    fail "We should never see this test";
}

sub test_this_should_be_run {
    for ( 1 .. 5 ) {
        pass "This is test number $_ in this method";
    }
}

sub expected_test_events {
    return (
        Note =>
          { message => "\nRunning tests for TestsFor::Basic::Subclass\n\n" },
        Note => { message => 'TestsFor::Basic::Subclass' },
        Subtest => [
            {   name => 'TestsFor::Basic::Subclass',
                pass => bool(1),
            },
            Plan => { max     => 5 },
            Note => { message => 'TestsFor::Basic::Subclass->test_me()' },
            Note => { message => 'test_me' },
            Subtest => [
                {   name => 'test_me',
                    pass => bool(1),
                },
                Ok => {
                    pass => bool(1),
                    name =>
                      'I overrode my parent! (TestsFor::Basic::Subclass)',
                },
                Plan => { max => 1 },
            ],
            Note => { message => 'TestsFor::Basic::Subclass->test_my_instance_name()' },
            Note => { message => 'test_my_instance_name' },
            Subtest => [
                {   name => 'test_my_instance_name',
                    pass => bool(1),
                },
                Ok => {
                    pass => bool(1),
                    name => 'test_instance_name matches class name',
                },
                Plan => { max => 1 },
            ],
            Note =>
              { message => 'TestsFor::Basic::Subclass->test_reporting()' },
            Note => { message => 'test_reporting' },
            Subtest => [
                {   name => 'test_reporting',
                    pass => bool(1),
                },
                Ok => {
                    pass => bool(1),
                    name =>
                      'current_instance() should report the correct class name',
                },
                Ok => {
                    pass => bool(1),
                    name =>
                      '... and we should also be able to get the current method name',
                },
                Ok => {
                    pass => bool(1),
                    name => 'test_setup() should know our current class name',
                },
                Ok => {
                    pass => bool(1),
                    name => '... and our current method name',
                },
                Plan => { max => 4 },
            ],
            Note =>
              { message => 'TestsFor::Basic::Subclass->test_this_baby()' },
            Note => { message => 'test_this_baby' },
            Subtest => [
                {   name => 'test_this_baby',
                    pass => bool(1),
                },
                Ok => {
                    pass => bool(1),
                    name =>
                      'This should run before my parent method (TestsFor::Basic::Subclass)',
                },
                Ok => {
                    pass => bool(1),
                    name => 'whee! (TestsFor::Basic::Subclass)',
                },
                Ok => {
                    pass => bool(1),
                    name => 'test_setup() should know our current class name',
                },
                Ok => {
                    pass => bool(1),
                    name => '... and our current method name',
                },
                Plan => { max => 4 },
            ],
            Note => {
                message =>
                  'TestsFor::Basic::Subclass->test_this_should_be_run()'
            },
            Note => { message => 'test_this_should_be_run' },
            Subtest => [
                {   name => 'test_this_should_be_run',
                    pass => bool(1),
                },
                Ok => {
                    pass => bool(1),
                    name => 'This is test number 1 in this method',
                },
                Ok => {
                    pass => bool(1),
                    name => 'This is test number 2 in this method',
                },
                Ok => {
                    pass => bool(1),
                    name => 'This is test number 3 in this method',
                },
                Ok => {
                    pass => bool(1),
                    name => 'This is test number 4 in this method',
                },
                Ok => {
                    pass => bool(1),
                    name => 'This is test number 5 in this method',
                },
                Plan => { max => 5 },
            ],
        ],
    );
}

1;
