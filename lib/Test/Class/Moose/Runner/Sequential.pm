package Test::Class::Moose::Runner::Sequential;

# ABSTRACT: Run tests sequentially

use 5.10.0;
use Moose 2.0000;
use Carp;
use namespace::autoclean;
with 'Test::Class::Moose::Role::Runner';

use Test::Most ();

has 'test_configuration' => (
    is       => 'ro',
    isa      => 'Test::Class::Moose::Config',
    required => 1,
);

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
Test instances:  @{[ $report->num_test_instances ]}
Test methods:    @{[ $report->num_test_methods ]}
Total tests run: @{[ $report->num_tests_run ]}
END
    $builder->done_testing;
    $report->_end_benchmark;
    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
