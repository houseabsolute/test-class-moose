package TestsFor::Basic;

use Test::Class::Moose bare => 1;

use Test2::Tools::Basic qw( ok );
use Test2::Tools::Compare qw( array call end event is T );

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

sub test_my_instance_name {
    my $self = shift;
    is $self->test_instance_name, ref $self,
      'test_instance_name matches class name';
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
    event Subtest => sub {
        call name      => 'TestsFor::Basic';
        call pass      => T();
        call subevents => array {
            event Plan => sub {
                call max => 4;
            };
            event Subtest => sub {
                call name      => 'test_me';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call pass => T();
                        call name => 'test_me() ran (TestsFor::Basic)';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => 'this is another test (TestsFor::Basic)';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name =>
                          'test_setup() should know our current class name';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => '... and our current method name';
                    };
                    event Plan => sub {
                        call max => 4;
                    };
                    end();
                };
            };
            event Subtest => sub {
                call name      => 'test_my_instance_name';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call pass => T();
                        call name => 'test_instance_name matches class name';
                    };
                    event Plan => sub {
                        call max => 1;
                    };
                    end();
                };
            };
            event Subtest => sub {
                call name      => 'test_reporting';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call pass => T();
                        call name =>
                          'current_instance() should report the correct class name';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name =>
                          '... and we should also be able to get the current method name';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name =>
                          'test_setup() should know our current class name';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => '... and our current method name';
                    };
                    event Plan => sub {
                        call max => 4;
                    };
                    end();
                };
            };
            event Subtest => sub {
                call name      => 'test_this_baby';
                call pass      => T();
                call subevents => array {
                    event Ok => sub {
                        call pass => T();
                        call name => 'whee! (TestsFor::Basic)';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name =>
                          'test_setup() should know our current class name';
                    };
                    event Ok => sub {
                        call pass => T();
                        call name => '... and our current method name';
                    };
                    event Plan => sub {
                        call max => 3;
                    };
                    end();
                };
            };
            end();
        };
    };
}

1;
