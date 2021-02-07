package Test::Reporting;

use strict;
use warnings;
use namespace::autoclean;

use Test2::Tools::Basic qw( ok );
use Test2::Tools::Class qw( can_ok isa_ok );
use Test2::Tools::Compare qw( call end field hash is object T validator );
use Test2::Tools::Subtest qw( subtest_streamed );

use Scalar::Util 'looks_like_number';

use Exporter qw( import );

our @EXPORT_OK = 'test_report';

my $PosOrZero
  = validator( 'number >= 0' => sub { looks_like_number($_) && $_ >= 0 } );

sub test_report {
    my $report = shift;
    my $expect = shift;

    is( $report->timing_data,
        _test_timing_data($expect),
        'timing data for entire report'
    );

    my @got_classes = $report->all_test_classes;
    is( [ sort map { $_->name } @got_classes ],
        [ sort keys %{ $expect->{classes} } ],
        'class reports have expected names'
    );

    for my $method (qw( num_tests_run num_test_instances num_test_methods )) {
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
                    $class_name->run_control_methods_on_skip,
                );
            }
        );
    }
}

sub _test_timing_data {
    my $expect = shift;

    return hash {
        _time_field();
        field class => hash {
            for my $class ( keys %{ $expect->{classes} } ) {
                field $class => _class_timing_structure(
                    $expect->{classes}{$class},
                    $class->run_control_methods_on_skip,
                );
            }
            end();
        };
        end();
    };
}

sub _class_timing_structure {
    my $expect                      = shift;
    my $always_runs_control_methods = shift;

    return hash {
        _time_field();
        if ( $expect->{instances} ) {
            field instance => hash {
                for my $instance ( keys %{ $expect->{instances} } ) {
                    field $instance => _instance_timing_structure(
                        $expect->{instances}{$instance},
                        $always_runs_control_methods,
                    );
                }
                end();
            };
        }
        end();
    };
}

sub _instance_timing_structure {
    my $expect                      = shift;
    my $always_runs_control_methods = shift;

    return hash {
        _time_field();
        field control => hash {
            field test_startup => hash {
                _time_field();
                end();
            };

            unless ( $expect->{is_skipped}->name eq 'TRUE'
                && !$always_runs_control_methods )
            {
                field test_shutdown => hash {
                    _time_field();
                    end();
                };
            }

            end();
        };

        return unless keys %{ $expect->{methods} };

        field method => hash {
            for my $method ( keys %{ $expect->{methods} } ) {
                field $method => _method_timing_structure(
                    $expect->{methods}{$method},
                    $always_runs_control_methods,
                );
            }
            end();
        };
        end();
    };
}

sub _method_timing_structure {
    my $expect                      = shift;
    my $always_runs_control_methods = shift;

    return hash {
        _time_field();
        field control => hash {
            field test_setup => hash {
                _time_field();
                end();
            };

            unless ( $expect->{is_skipped}->name eq 'TRUE'
                && !$always_runs_control_methods )
            {
                field test_teardown => hash {
                    _time_field();
                    end();
                };
            }

            end();
        };
        end();
    };
}

sub _time_field {
    return field time => hash {
        field real   => $PosOrZero;
        field system => $PosOrZero;
        field user   => $PosOrZero;
        end();
    };
}

sub _test_class_report {
    my $class_report                = shift;
    my $expect                      = shift;
    my $always_runs_control_methods = shift;

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
                    $always_runs_control_methods,
                );
            }
        );
    }
}

sub _test_instance_report {
    my $instance_report             = shift;
    my $expect                      = shift;
    my $always_runs_control_methods = shift;

    _test_report_time($instance_report);

    for my $method (qw( is_skipped passed )) {
        is( $instance_report->$method,
            $expect->{$method},
            $method
        );
    }

    my @control = 'test_startup';
    push @control, 'test_shutdown'
      if $always_runs_control_methods || !$instance_report->is_skipped;

    _test_control_methods(
        $instance_report,
        @control,
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
                    $always_runs_control_methods,
                );
            }
        );
    }
}

sub _test_method_report {
    my $method_report               = shift;
    my $expect                      = shift;
    my $always_runs_control_methods = shift;

    _test_report_time($method_report);

    for my $method (qw( is_skipped passed num_tests_run tests_planned )) {
        is( $method_report->$method,
            $expect->{$method},
            $method
        );
    }

    my @control = 'test_setup';
    push @control, 'test_teardown'
      if $always_runs_control_methods || !$method_report->is_skipped;

    _test_control_methods( $method_report, @control );
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

{
    my $pos
      = validator( 'number > 0', sub { looks_like_number($_) && $_ > 0 } );

    sub _test_report_time {
        my $report = shift;

        subtest_streamed(
            'timing report',
            sub {
                is( $report,
                    object {
                        call start_time => $pos;
                        call end_time   => $pos;
                    },
                    'report has start and end time'
                );

                can_ok( $report, 'time' );
                my $time = $report->time;
                isa_ok(
                    $time,
                    'Test::Class::Moose::Report::Time',
                );

                is( $time,
                    object {
                        call real   => $PosOrZero;
                        call system => $PosOrZero;
                        call user   => $PosOrZero;
                    },
                    'time object has expected values'
                );
            }
        );
    }
}

1;
