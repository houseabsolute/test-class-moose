package TestsFor::Basic;
use Test::Class::Moose;

use Test::Deep qw( bool );

has [ 'setup_class_found', 'setup_method_found' ] => (
    is  => 'rw',
    isa => 'Str',
);

sub test_setup {
    my $test             = shift;
    my $report           = $test->test_report;
    my $current_instance = $report->current_instance;
    $test->setup_class_found( $current_instance->name );
    $test->setup_method_found( $report->current_method->name );
}

sub test_me {
    my $test  = shift;
    my $class = ref $test;
    ok 1, "test_me() ran ($class)";
    ok 2, "this is another test ($class)";
    is $test->setup_class_found, $test->test_class,
      'test_setup() should know our current class name';
    is $test->setup_method_found, 'test_me',
      '... and our current method name';
}

sub test_this_baby {
    my $test  = shift;
    my $class = ref $test;
    is 2, 2, "whee! ($class)";
    is $test->setup_class_found, $test->test_class,
      'test_setup() should know our current class name';
    is $test->setup_method_found, 'test_this_baby',
      '... and our current method name';
}

sub test_reporting {
    my $test             = shift;
    my $report           = $test->test_report;
    my $current_instance = $report->current_instance;
    is $current_instance->name, $test->test_class,
      'current_instance() should report the correct class name';
    is $report->current_method->name, 'test_reporting',
      '... and we should also be able to get the current method name';
    is $test->setup_class_found, $test->test_class,
      'test_setup() should know our current class name';
    is $test->setup_method_found, 'test_reporting',
      '... and our current method name';
}

sub expected_test_events {
    return (
        Note => { message => "\nRunning tests for TestsFor::Basic\n\n" },
        Note => { message => 'TestsFor::Basic' },
        Subtest => [
            {   name => 'TestsFor::Basic',
                pass => bool(1),
            },
            Plan => { max     => 3 },
            Note => { message => 'TestsFor::Basic->test_me()' },
            Note => { message => 'test_me' },
            Subtest => [
                {   name => 'test_me',
                    pass => bool(1),
                },
                Ok => {
                    pass => bool(1),
                    name => 'test_me() ran (TestsFor::Basic)',
                },
                Ok => {
                    pass => bool(1),
                    name => 'this is another test (TestsFor::Basic)',
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
            Note => { message => 'TestsFor::Basic->test_reporting()' },
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
            Note => { message => 'TestsFor::Basic->test_this_baby()' },
            Note => { message => 'test_this_baby' },
            Subtest => [
                {   name => 'test_this_baby',
                    pass => bool(1),
                },
                Ok => {
                    pass => bool(1),
                    name => 'whee! (TestsFor::Basic)',
                },
                Ok => {
                    pass => bool(1),
                    name => 'test_setup() should know our current class name',
                },
                Ok => {
                    pass => bool(1),
                    name => '... and our current method name',
                },
                Plan => { max => 3 },
            ],
        ],
    );
}

1;
