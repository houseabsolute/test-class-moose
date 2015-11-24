package Test::Class::Moose::Executor::Sequential;

# ABSTRACT: Execute tests sequentially

use 5.10.0;
use Moose 2.0000;
use Carp;
use namespace::autoclean;
with 'Test::Class::Moose::Role::Executor';

use Test::Class::Moose::Report::Class;
use Test::Most 0.32 ();

sub runtests {
    my $self = shift;

    my $report = $self->test_report;
    $report->_start_benchmark;
    my @test_classes = $self->test_classes;

    my $builder = $self->test_configuration->builder;
    $builder->plan( tests => scalar @test_classes );

    foreach my $test_class (@test_classes) {
        Test::Most::explain("\nRunning tests for $test_class\n\n");
        $builder->subtest(
            $test_class,
            $self->_tcm_run_test_class($test_class),
        );
    }

    $builder->diag(<<"END") if $self->test_configuration->statistics;
Test classes:    @{[ $report->num_test_classes ]}
Test instances:  @{[ $report->num_test_instances ]}
Test methods:    @{[ $report->num_test_methods ]}
Total tests run: @{[ $report->num_tests_run ]}
END
    $builder->done_testing;
    $report->_end_benchmark;
    return $self;
}

sub _tcm_run_test_class {
    my ( $self, $test_class ) = @_;

    return sub {
        local *__ANON__ = 'ANON_TCM_RUN_TEST_CLASS';

        my $class_report
          = Test::Class::Moose::Report::Class->new( name => $test_class );
        $self->test_report->add_test_class($class_report);

        my %test_instances = $test_class->_tcm_make_test_class_instances(
            $self->test_configuration->args,
            test_report => $self->test_report,
        );

        unless (%test_instances) {
            my $message = "Skipping '$test_class': no test instances found";
            $class_report->skipped($message);
            $class_report->passed(1);
            $self->test_configuration->builder->plan( skip_all => $message );
            return;
        }

        $class_report->_start_benchmark;

        my $passed = 1;
        foreach my $test_instance_name ( sort keys %test_instances ) {
            my $test_instance = $test_instances{$test_instance_name};

            my $instance_report;
            if ( values %test_instances > 1 ) {
                $self->test_configuration->builder->subtest(
                    $test_instance_name,
                    sub {
                        $instance_report = $self->_tcm_run_test_instance(
                            $test_instance_name,
                            $test_instance,
                        );
                    },
                );
            }
            else {
                $instance_report = $self->_tcm_run_test_instance(
                    $test_instance_name,
                    $test_instance,
                );
            }

            $passed = 0 if not $instance_report->passed;
        }

        $class_report->passed($passed);
        $class_report->_end_benchmark;
    };
}

__PACKAGE__->meta->make_immutable;

1;
