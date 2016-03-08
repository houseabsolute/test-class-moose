package Test::Reporting;

use strict;
use warnings;

use Test2::Tools::Basic qw( ok );
use Test2::Tools::Class qw( can_ok isa_ok );
use Test2::Tools::Compare qw( field hash is validator );
use Test2::Tools::Subtest qw( subtest_streamed );

use Scalar::Util 'looks_like_number';

use Exporter qw( import );

our @EXPORT_OK = 'test_report';

sub test_report {
    my $report = shift;
    my $expect = shift;

    is( $report->timing_data,
        _timing_report_struct($expect),
        'timing data for entire report'
    );

    my @got_classes = $report->all_test_classes;
    is( [ sort map { $_->name } @got_classes ],
        [ sort keys %{ $expect->{classes} } ],
        'class reports have expected names'
    );

    for my $method (
        qw( is_parallel num_tests_run num_test_instances num_test_methods ))
    {
        is( $report->$method,
            $expect->{$method},
            $method
        );
    }

    for my $class_report (@got_classes) {
        my $class_name = $class_report->name;
        subtest_streamed(
            "report for class: $class_name" => sub {
                unless ( $expect->{classes}{$class_name} ) {
                    ok( 0, 'unexpected class in report: ' . $class_name );
                    return;
                }
                _test_class_report(
                    $class_report,
                    $expect->{classes}{$class_name},
                );
            }
        );
    }
}

sub _timing_report_struct {
    my $expect = shift;

    my $pos_or_zero
      = validator( 'number >= 0' => sub { looks_like_number($_) && $_ >= 0 }
      );
    my $time_field = sub {
        field time => hash {
            field real   => $pos_or_zero;
            field system => $pos_or_zero;
            field user   => $pos_or_zero;
        };
    };

    return hash {
        $time_field->();
        field class => hash {
            for my $class ( keys %{ $expect->{classes} } ) {
                field $class => hash {
                    $time_field->();
                    field instance => hash {
                        for my $instance (
                            keys %{ $expect->{classes}{$class}{instances} } )
                        {
                            field $instance => hash {
                                $time_field->();
                                field control => hash {
                                    field test_startup => hash {
                                        $time_field->();
                                    };
                                    field test_shutdown => hash {
                                        $time_field->();
                                    };
                                };
                                field method => hash {
                                    for my $method (
                                        keys %{
                                            $expect->{classes}{$class}
                                              {instances}{$instance}{methods}
                                        }
                                      )
                                    {
                                        field $method => hash {
                                            $time_field->();
                                            field control => hash {
                                                field test_setup => hash {
                                                    $time_field->();
                                                };
                                                field test_teardown => hash {
                                                    $time_field->();
                                                };
                                            };
                                        };
                                    }
                                };
                            };
                        }
                    };
                };
            }
        };
    };
}

# sub _class_cmp_deeply {
#     my $class = shift;

#     my %instance_control_cmp = (
#         control => {
#             test_startup  => \%time_cmp,
#             test_shutdown => \%time_cmp,
#         },
#     );

#     my %method_control_cmp = (
#         control => {
#             test_setup    => \%time_cmp,
#             test_teardown => \%time_cmp,
#         },
#     );

#     return (
#         $class => {
#             %time_cmp,
#             instance => {
#                 $class => {
#                     %time_cmp,
#                     %instance_control_cmp,
#                     method => {
#                         map { $_ => { %time_cmp, %method_control_cmp } }
#                           @{ $expected_methods{$class} },
#                     },
#                 },
#             },
#         }
#     );
# }

sub _test_class_report {
    my $class_report = shift;
    my $expect       = shift;

    _test_report_time($class_report);

    for my $method (qw( is_skipped passed )) {
        is( $class_report->$method,
            $expect->{$method},
            $method
        );
    }

    my @got_instances = $class_report->all_test_instances;
    is( scalar @got_instances,
        scalar keys %{ $expect->{instances} },
        'number of instances'
    );

    for my $instance_report (@got_instances) {
        my $instance_name = $instance_report->name;
        subtest_streamed(
            "report for instance: $instance_name" => sub {
                _test_instance_report(
                    $instance_report,
                    $expect->{instances}{$instance_name},
                );
            }
        );
    }
}

sub _test_instance_report {
    my $instance_report = shift;
    my $expect          = shift;

    _test_report_time($instance_report);

    for my $method (qw( is_skipped passed )) {
        is( $instance_report->$method,
            $expect->{$method},
            $method
        );
    }

    _test_control_methods(
        $instance_report,
        qw( test_startup test_shutdown )
    );

    my @methods = $instance_report->all_test_methods;
    is( [ sort map { $_->name } @methods ],
        [ sort keys %{ $expect->{methods} } ],
        'methods'
    );

    for my $method_report (@methods) {
        my $method_name = $method_report->name;
        subtest_streamed(
            "report for method: $method_name" => sub {
                _test_method_report(
                    $method_report,
                    $expect->{methods}{$method_name},
                );
            }
        );
    }
}

sub _test_method_report {
    my $method_report = shift;
    my $expect        = shift;

    _test_report_time($method_report);

    for my $method (qw( is_skipped passed num_tests_run tests_planned )) {
        is( $method_report->$method,
            $expect->{$method},
            $method
        );
    }

    _test_control_methods(
        $method_report,
        qw( test_setup test_teardown ),
    );
}

sub _test_control_methods {
    my $report = shift;

    for my $control (@_) {
        subtest_streamed(
            "report for control method: $control" => sub {
                my $report_meth   = $control . '_method';
                my $method_report = $report->$report_meth;
                _test_report_time($method_report);
                isa_ok(
                    $method_report,
                    'Test::Class::Moose::Report::Method',
                );
                is( $method_report->name,
                    $control,
                    "$control method report name"
                );
                is( $method_report->num_tests_run,
                    0,
                    "no tests run in $control"
                );
            }
        );
    }
}

sub _test_report_time {
    my $report = shift;

    subtest_streamed(
        'timing report',
        sub {
            can_ok( $report, 'time' );
            my $time = $report->time;
            isa_ok(
                $time,
                'Test::Class::Moose::Report::Time',
            );

            for my $method (qw( real user system )) {
                ok( looks_like_number( $time->$method ),
                    qq{\$time->$method returns a number}
                );
                ok( $time->$method >= 0,
                    'number is greater than or equal to zero'
                );
            }
        }
    );
}

1;
