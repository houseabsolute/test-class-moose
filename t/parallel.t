#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib', 't/lib';

use Test::Requires {
    'Parallel::ForkManager' => 0,
};

use Test2::Bundle::Extended;
use Test::Events;

use Test::Class::Moose::Load qw( t/parallellib );
use Test::Class::Moose::Runner;

plan skip_all =>
  'These tests currently fail on Windows for reasons we do not understand. Patches welcome.'
  if $^O =~ /Win32/;

my $test_runner = Test::Class::Moose::Runner->new(
    show_timing => 0,
    jobs        => 2,
    statistics  => 0,
);

test_events(
    intercept { $test_runner->runtests },
    array {
        event Plan => sub {
            call max => 4;
        };
        event Subtest => sub {
            call name      => 'TestsFor::Alpha';
            call pass      => T();
            call subevents => array {
                event Plan => sub {
                    call max => 2;
                };
                event Subtest => sub {
                    call name      => 'test_alpha_first';
                    call pass      => T();
                    call subevents => array {
                        event Ok => sub {
                            call name => undef;
                            call pass => T();
                        };
                        event Ok => sub {
                            call name => undef;
                            call pass => T();
                        };
                        event Plan => sub {
                            call max => 2;
                        };
                        end();
                    };
                };
                event Subtest => sub {
                    call name      => 'test_second';
                    call pass      => T();
                    call subevents => array {
                        event Ok => sub {
                            call name => 'make sure plans work';
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
        event Subtest => sub {
            call name      => 'TestsFor::Alpha::Subclass';
            call pass      => T();
            call subevents => array {
                event Plan => sub {
                    call max => 3;
                };
                event Subtest => sub {
                    call name      => 'test_alpha_first';
                    call pass      => T();
                    call subevents => array {
                        event Ok => sub {
                            call name => undef;
                            call pass => T();
                        };
                        event Ok => sub {
                            call name => undef;
                            call pass => T();
                        };
                        event Plan => sub {
                            call max => 2;
                        };
                        end();
                    };
                };
                event Subtest => sub {
                    call name      => 'test_another';
                    call pass      => T();
                    call subevents => array {
                        event Ok => sub {
                            call name => undef;
                            call pass => T();
                        };
                        event Plan => sub {
                            call max => 1;
                        };
                        end();
                    };
                };
                event Subtest => sub {
                    call name      => 'test_second';
                    call pass      => T();
                    call subevents => array {
                        event Ok => sub {
                            call name => 'make sure plans work';
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
        event Subtest => sub {
            call name      => 'TestsFor::Beta';
            call pass      => T();
            call subevents => array {
                event Plan => sub {
                    call max => 2;
                };
                event Subtest => sub {
                    call name      => 'test_beta_first';
                    call pass      => T();
                    call subevents => array {
                        event Ok => sub {
                            call name => undef;
                            call pass => T();
                        };
                        event Ok => sub {
                            call name => undef;
                            call pass => T();
                        };
                        event Plan => sub {
                            call max => 2;
                        };
                        end();
                    };
                };
                event Subtest => sub {
                    call name      => 'test_second';
                    call pass      => T();
                    call subevents => array {
                        event Ok => sub {
                            call name => undef;
                            call pass => T();
                        };
                        event Ok => sub {
                            call name => undef;
                            call pass => T();
                        };
                        event Plan => sub {
                            call max => 2;
                        };
                        end();
                    };
                };
                end();
            };
        };
        event Subtest => sub {
            call name      => 'TestsFor::Sequential';
            call pass      => T();
            call subevents => array {
                event Plan => sub {
                    call max => 2;
                };
                event Subtest => sub {
                    call name      => 'test_sequential_first';
                    call pass      => T();
                    call subevents => array {
                        event Ok => sub {
                            call name => undef;
                            call pass => T();
                        };
                        event Plan => sub {
                            call max => 1;
                        };
                        end();
                    };
                };
                event Subtest => sub {
                    call name      => 'test_sequential_second';
                    call pass      => T();
                    call subevents => array {
                        event Ok => sub {
                            call name => undef;
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
    'parallel tests produce the expected events'
);

done_testing();
