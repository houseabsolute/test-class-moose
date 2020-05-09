use strict;
use warnings;

use FindBin qw( $Bin );
use lib "$Bin/lib";

use Test2::API qw( intercept );
use Test2::V0;
use Test::Events;

use Test::Class::Moose::Load "$Bin/basiclib";
use Test::Class::Moose::Runner;

my $runner = Test::Class::Moose::Runner->new(
    {   show_timing => 0,
        statistics  => 0,
        include     => qr/baby/,
    }
);

my %methods_for = (
    'TestsFor::Basic'           => ['test_this_baby'],
    'TestsFor::Basic::Subclass' => ['test_this_baby'],
);
my @test_classes = sort $runner->test_classes;

foreach my $class (@test_classes) {
    is
      [ $runner->_executor->_test_methods_for( $class->new ) ],
      $methods_for{$class},
      "$class should have the correct test methods";
}

test_events_is(
    intercept { $runner->runtests },
    array {
        event Plan => sub {
            call max => 2;
        };
        event Subtest => sub {
            call name      => 'TestsFor::Basic';
            call pass      => T();
            call subevents => array {
                event Plan => sub {
                    call max => 1;
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
            end();
        };
        event Subtest => sub {
            call name      => 'TestsFor::Basic::Subclass';
            call pass      => T();
            call subevents => array {
                event Plan => sub {
                    call max => 1;
                };
                event Subtest => sub {
                    call name      => 'test_this_baby';
                    call pass      => T();
                    call subevents => array {
                        event Ok => sub {
                            call pass => T();
                            call name =>
                              'This should run before my parent method (TestsFor::Basic::Subclass)';
                        };
                        event Ok => sub {
                            call pass => T();
                            call name => 'whee! (TestsFor::Basic::Subclass)';
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
                end();
            };
            end();
        };
        end();
    },
    'events when only one method is included'
);

ok my $report = $runner->test_report,
  'We should be able to fetch reporting information from the test suite';
isa_ok $report, 'Test::Class::Moose::Report';
is $report->num_test_instances, 2,
  '... and it should return the correct number of test class instances';
is $report->num_test_methods, 2,
  '... and the correct number of test methods';
is $report->num_tests_run, 7, '... and the correct number of tests';

$runner = Test::Class::Moose::Runner->new(
    {   show_timing => 0,
        statistics  => 0,
        exclude     => qr/baby/,
    }
);

%methods_for = (
    'TestsFor::Basic' => [
        qw/
          test_me
          test_my_instance_name
          test_reporting
          /
    ],
    'TestsFor::Basic::Subclass' => [
        qw/
          test_me
          test_my_instance_name
          test_reporting
          test_this_should_be_run
          /
    ],
);

foreach my $class (@test_classes) {
    is
      [ $runner->_executor->_test_methods_for( $class->new ) ],
      $methods_for{$class},
      "$class should have the correct test methods";
}

test_events_is(
    intercept { $runner->runtests },
    array {
        event Plan => sub {
            call max => 2;
        };
        event Subtest => sub {
            call name      => 'TestsFor::Basic';
            call pass      => T();
            call subevents => array {
                event Plan => sub {
                    call max => 3;
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
                            call name =>
                              'this is another test (TestsFor::Basic)';
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
                            call name =>
                              'test_instance_name matches class name';
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
                end();
            };
        };
        event Subtest => sub {
            call name      => 'TestsFor::Basic::Subclass';
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
                            call name =>
                              'I overrode my parent! (TestsFor::Basic::Subclass)';
                        };
                        event Plan => sub {
                            call max => 1;
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
                            call name =>
                              'test_instance_name matches class name';
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
                    call name      => 'test_this_should_be_run';
                    call pass      => T();
                    call subevents => array {
                        event Ok => sub {
                            call pass => T();
                            call name =>
                              'This is test number 1 in this method';
                        };
                        event Ok => sub {
                            call pass => T();
                            call name =>
                              'This is test number 2 in this method';
                        };
                        event Ok => sub {
                            call pass => T();
                            call name =>
                              'This is test number 3 in this method';
                        };
                        event Ok => sub {
                            call pass => T();
                            call name =>
                              'This is test number 4 in this method';
                        };
                        event Ok => sub {
                            call pass => T();
                            call name =>
                              'This is test number 5 in this method';
                        };
                        event Plan => sub {
                            call max => 5;
                        };
                        end();
                    };
                };
                end();
            };
        };
        end();
    },
    'events when one method is excluded'
);

ok $report = $runner->test_report,
  'We should be able to fetch reporting information from the test suite';
isa_ok $report, 'Test::Class::Moose::Report';
is $report->num_test_instances, 2,
  '... and it should return the correct number of test class instances';
is $report->num_test_methods, 7,
  '... and the correct number of test methods';
is $report->num_tests_run, 20, '... and the correct number of tests';

done_testing;
