use strict;
use warnings;

use Test2::V0;
use Test2::API qw( intercept );

use FindBin qw( $Bin );
use Test::Class::Moose::Load "$Bin/reportpassedlib";
use Test::Class::Moose::Runner;

my $runner = Test::Class::Moose::Runner->new( show_timing => 0 );
intercept { $runner->runtests };
my $report = $runner->test_report;

# note: because of a possible bug in Test::Builder::subtest returning a fail
# status, even if the test is TODO, we rely on that feature to make these
# tests easier: $report->passed reports false if a test failed, even if it's a
# TODO test.
my %expect = (
    'TestsFor::Fail' => {
        passed    => 0,
        instances => {
            'TestsFor::Fail' => {
                passed  => 0,
                methods => {
                    test_a_bad  => 0,
                    test_a_good => 1,
                    test_b_bad  => 0,
                    test_b_good => 1,
                },
            },
        },
    },
    'TestsFor::FailChild' => {
        passed    => 1,
        instances => {
            'TestsFor::FailChild' => {
                passed  => 1,
                methods => {
                    test_a_bad   => 1,
                    test_a_good  => 1,
                    test_another => 1,
                    test_b_bad   => 1,
                    test_b_good  => 1,
                },
            },
        },
    },
    'TestsFor::Pass' => {
        passed    => 1,
        instances => {
            'TestsFor::Pass' => {
                passed  => 1,
                methods => {
                    test_a_good   => 1,
                    test_a_good_2 => 1,
                    test_b_good   => 1,
                    test_b_good_2 => 1,
                },
            },
        },
    },
);

my %got;
for my $class ( $report->all_test_classes ) {
    my $class_name = $class->name;
    $got{$class_name}{passed} = $class->passed;
    can_ok( $class, 'time' );
    isa_ok( $class->time, 'Test::Class::Moose::Report::Time' );

    for my $instance ( $class->all_test_instances ) {
        my $instance_name = $instance->name;
        $got{$class_name}{instances}{$instance_name}{passed}
          = $instance->passed;
        can_ok( $instance, 'time' );
        isa_ok( $instance->time, 'Test::Class::Moose::Report::Time' );

        for my $method ( $instance->all_test_methods ) {
            $got{$class_name}{instances}{$instance_name}{methods}
              { $method->name } = $method->passed;
            can_ok( $method, 'time' );
            isa_ok( $method->time, 'Test::Class::Moose::Report::Time' );
        }
    }
}

is( [ sort keys %got ],
    [ sort keys %expect ],
    'ran all the classes we expected',
);

for my $class ( sort keys %expect ) {
    is( $got{$class}{passed},
        $expect{$class}{passed},
        "got expected pass/fail status for $class class"
    );
    is( [ sort keys %{ $got{$class}{instances} } ],
        [ sort keys %{ $expect{$class}{instances} } ],
        "ran all the $class instances we expected",
    );

    for my $instance ( sort keys %{ $expect{$class}{instances} } ) {
        is( $got{$class}{instances}{$instance}{passed},
            $expect{$class}{instances}{$instance}{passed},
            "got expected pass/fail status for $instance instance"
        );
        is( [ sort keys %{ $got{$class}{instances}{$instance}{methods} } ],
            [ sort keys %{ $expect{$class}{instances}{$instance}{methods} } ],
            "ran all the $instance methods we expected",
        );

        for my $method (
            sort keys %{ $expect{$class}{instances}{$instance}{methods} } )
        {
            is( $got{$class}{instances}{$instance}{methods}{$method},
                $expect{$class}{instances}{$instance}{methods}{$method},
                "got expected pass/fail status for $method method"
            );
        }
    }
}

done_testing;
