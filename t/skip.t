#!/usr/bin/env perl

use lib 'lib';

use Test2::Bundle::Extended;

use Test::Class::Moose::Load qw(t/skiplib);
use Test::Class::Moose::Runner;

my $runner = Test::Class::Moose::Runner->new;

is( intercept { $runner->runtests },
    array {
        event Plan => sub {
            call max => 2;
        };
        event Note => sub {
            call message => "\nRunning tests for TestsFor::Basic\n\n";
        };
        event Subtest => sub {
            call name      => 'TestsFor::Basic';
            call pass      => T();
            call subevents => array {
                event Plan => sub {
                    call directive => 'SKIP';
                    call reason    => 'all methods should be skipped';
                    call max       => 0;
                };
                end();
            };
        };
        event Note => sub {
            call message =>
              "\nRunning tests for TestsFor::SkipSomeMethods\n\n";
        };
        event Subtest => sub {
            call name      => 'TestsFor::SkipSomeMethods';
            call pass      => T();
            call subevents => array {
                event Plan => sub {
                    call max => 3;
                };
                event Note => sub {
                    call message => 'TestsFor::SkipSomeMethods->test_again()';
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
                event Note => sub {
                    call message => 'TestsFor::SkipSomeMethods->test_me()';
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
                event Note => sub {
                    call message =>
                      'TestsFor::SkipSomeMethods->test_this_baby()';
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
                end();
            };
        };
        end();
    },
    'got expected events for skip tests'
);

my $classes = $runner->test_report->test_classes;

{
    is $classes->[0]->name, 'TestsFor::Basic',
      'Our first class should be listed in reporting';

    my $instances = $classes->[0]->test_instances;

    ok $instances->[0]->is_skipped, '... and it should be listed as skipped';
    ok $instances->[0]->passed, '... and it is reported as passed';
}

{
    is $classes->[1]->name, 'TestsFor::SkipSomeMethods',
      'Our second class should be listed in reporting';

    my $instances = $classes->[1]->test_instances;
    ok !$instances->[0]->is_skipped,
      '... and it should NOT be listed as skipped';
    ok $instances->[0]->passed, '... and it is reported as passed';
    my $methods = $instances->[0]->test_methods;

    is @$methods, 3, '... and it should have three test methods';

    my @skipped = grep { $_->is_skipped } @$methods;
    is scalar @skipped, 1,
      '... and the correct number of methods should be skipped';
    is $skipped[0]->name, 'test_me',
      '... and they should be the correct methods';
    is $skipped[0]->num_tests_run, 0,
      '... and we should have 0 tests run';
}

done_testing;
