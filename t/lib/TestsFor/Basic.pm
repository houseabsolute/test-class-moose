package TestsFor::Basic;
use Test::Class::Moose;

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

sub test_reporting {
    my $test          = shift;
    my $report        = $test->test_report;
    my $current_class = $report->current_class;
    is $current_class->name, $test->test_class,
      'current_class() should report the correct class name';
    TODO: {
        local $TODO = 'current method is not yet working';
        is $report->current_method->name, 'test_reporting',
          '... and we should also be able to get the current method name';
    }
}

1;
