package Test::Class::Moose::Executor::Sequential;

# ABSTRACT: Execute tests sequentially

use 5.10.0;

our $VERSION = '0.70';

use Moose 2.0000;
use Carp;
use namespace::autoclean;
with 'Test::Class::Moose::Role::Executor';

use Test::Class::Moose::Report::Class;
use Test2::API qw( context );
use Test2::Tools::AsyncSubtest qw( subtest_start subtest_run subtest_finish );
use Try::Tiny;

sub runtests {
    my $self = shift;

    my $report = $self->test_report;
    $report->_start_benchmark;
    my @test_classes = $self->test_classes;

    my $ctx = context();
    try {
        $ctx->plan( scalar @test_classes );

        foreach my $test_class (@test_classes) {
            $ctx->note("\nRunning tests for $test_class\n\n");
            my $subtest = subtest_start($test_class);
            subtest_run(
                $subtest,
                sub { $self->_run_test_class($test_class) },
            );
            subtest_finish($subtest);
        }

        $ctx->diag(<<"END") if $self->test_configuration->statistics;
Test classes:    @{[ $report->num_test_classes ]}
Test instances:  @{[ $report->num_test_instances ]}
Test methods:    @{[ $report->num_test_methods ]}
Total tests run: @{[ $report->num_tests_run ]}
END

        $ctx->done_testing;
    }
    catch {
        die $_;
    }
    finally {
        $ctx->release;
    };

    $report->_end_benchmark;
    return $self;
}

sub _run_test_class {
    my ( $self, $test_class ) = @_;

    my $class_report
      = Test::Class::Moose::Report::Class->new( name => $test_class );
    $self->test_report->add_test_class($class_report);

    my $ctx = context();

    my $passed = 1;
    try {
        my @test_instances = $test_class->_tcm_make_test_class_instances(
            $self->test_configuration->args,
            test_report => $self->test_report,
        );

        unless (@test_instances) {
            my $message = "Skipping '$test_class': no test instances found";
            $class_report->skipped($message);
            $class_report->passed(1);
            $ctx->plan( 0, 'SKIP' => $message );
            return;
        }

        $class_report->_start_benchmark;

        foreach my $test_instance (
            sort { $a->test_instance_name cmp $b->test_instance_name }
            @test_instances )
        {
            my $instance_report;
            if ( @test_instances > 1 ) {
                my $subtest
                  = subtest_start( $test_instance->test_instance_name );
                subtest_run(
                    $subtest,
                    sub {
                        $instance_report = $self->_run_test_instance(
                            $class_report,
                            $test_instance,
                        );
                    },
                );
                subtest_finish($subtest);
            }
            else {
                $instance_report = $self->_run_test_instance(
                    $class_report,
                    $test_instance,
                );
            }

            $passed = 0 if not $instance_report->passed;
        }
    }
    catch {
        die $_;
    }
    finally {
        $ctx->release;
    };

    $class_report->passed($passed);
    $class_report->_end_benchmark;
}

__PACKAGE__->meta->make_immutable;

1;

=for Pod::Coverage Tags Tests runtests
