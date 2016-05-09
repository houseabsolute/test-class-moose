package Test::Class::Moose::Role::Executor;

# ABSTRACT: Common code for Runner classes

use 5.10.0;

our $VERSION = '0.71';

use Moose::Role 2.0000;
use Carp;
use namespace::autoclean;

use List::Util qw(shuffle);
use List::SomeUtils qw(uniq);
use Test::Builder;
use Test::Most;
use Try::Tiny;
use Test::Class::Moose::Config;
use Test::Class::Moose::Report;
use Test::Class::Moose::Report::Instance;
use Test::Class::Moose::Report::Method;
use Test::Class::Moose::AttributeRegistry;

requires 'runtests';

has 'test_configuration' => (
    is  => 'ro',
    isa => 'Test::Class::Moose::Config',
);

has 'test_report' => (
    is      => 'ro',
    isa     => 'Test::Class::Moose::Report',
    builder => '_build_test_report',
);

sub _build_test_report {
    my $self = shift;

    # XXX - This isn't very elegant and won't work well in the face of other
    # types of Executors. However, the real fix is to make parallel reporting
    # actually work so the report doesn't have to care about this.
    return Test::Class::Moose::Report->new(
        is_parallel => ( ref $self ) =~ /::Parallel$/ ? 1 : 0,
    );
}

sub _tcm_run_test_instance {
    my ( $self, $test_instance_name, $test_instance ) = @_;

    my $config  = $self->test_configuration;
    my $builder = $config->builder;
    my $report  = $self->test_report;

    local $0 = "$0 - $test_instance_name"
      if $config->set_process_name;

    # set up test class reporting
    my $instance_report = Test::Class::Moose::Report::Instance->new(
        {   name => $test_instance_name,
        }
    );
    $report->current_class->add_test_instance($instance_report)
      if $report->current_class;

    my @test_methods = $self->_tcm_test_methods_for_instance($test_instance);

    unless (@test_methods) {
        my $message = "Skipping '$test_instance_name': no test methods found";
        $instance_report->skipped($message);
        $instance_report->passed(1);
        $builder->plan( skip_all => $message );
        return $instance_report;
    }
    $instance_report->_start_benchmark;

    $report->_inc_test_methods( scalar @test_methods );

    # startup
    unless (
        my $report = $self->_tcm_run_test_control_method(
            $test_instance, 'test_startup', $instance_report
        )
      )
    {
        fail "test_startup failed";
        $instance_report->passed(0);
        return $instance_report;
    }

    if ( my $message = $test_instance->test_skip ) {

        # test_startup skipped the class
        $instance_report->skipped($message);
        $instance_report->passed(1);
        $builder->plan( skip_all => $message );
        return $instance_report;
    }

    $builder->plan( tests => scalar @test_methods );

    # run test methods

    my $all_passed = 1;
    foreach my $test_method (@test_methods) {
        my $method_report = $self->_tcm_run_test_method(
            $test_instance,
            $test_method,
            $instance_report,
        );
        $report->_inc_tests( $method_report->num_tests_run );
        $all_passed = 0 if not $method_report->passed;
    }
    $instance_report->passed($all_passed);

    # shutdown
    $self->_tcm_run_test_control_method(
        $test_instance,
        'test_shutdown',
        $instance_report,
    ) or $instance_report->passed( fail("test_shutdown() failed") );

    # finalize reporting
    $instance_report->_end_benchmark;
    if ( $config->show_timing ) {
        my $time = $instance_report->time->duration;
        $builder->diag("$test_instance_name: $time");
    }
    return $instance_report;
}

sub _tcm_test_methods_for_instance {
    my ( $self, $test_instance ) = @_;

    my @filtered = $self->_tcm_filtered_test_methods($test_instance);
    return uniq(
        $self->test_configuration->randomize
        ? shuffle(@filtered)
        : sort @filtered
    );
}

sub _tcm_filtered_test_methods {
    my ( $self, $test_instance ) = @_;

    my @method_list = $test_instance->test_methods;
    if ( my $include = $self->test_configuration->include ) {
        @method_list = grep {/$include/} @method_list;
    }
    if ( my $exclude = $self->test_configuration->exclude ) {
        @method_list = grep { !/$exclude/ } @method_list;
    }

    return $self->_tcm_filter_by_tag(
        $test_instance->test_class,
        \@method_list
    );
}

sub _tcm_filter_by_tag {
    my ( $self, $class, $methods ) = @_;

    my @filtered_methods = @$methods;
    if ( my $include = $self->test_configuration->include_tags ) {
        my @new_method_list;
        foreach my $method (@filtered_methods) {
            foreach my $tag (@$include) {
                if (Test::Class::Moose::AttributeRegistry->method_has_tag(
                        $class, $method, $tag
                    )
                  )
                {
                    push @new_method_list => $method;
                }
            }
        }
        @filtered_methods = @new_method_list;
    }
    if ( my $exclude = $self->test_configuration->exclude_tags ) {
        my @new_method_list = @filtered_methods;
        foreach my $method (@filtered_methods) {
            foreach my $tag (@$exclude) {
                if (Test::Class::Moose::AttributeRegistry->method_has_tag(
                        $class, $method, $tag
                    )
                  )
                {
                    @new_method_list
                      = grep { $_ ne $method } @new_method_list;
                }
            }
        }
        @filtered_methods = @new_method_list;
    }
    return @filtered_methods;
}

my %TEST_CONTROL_METHODS = map { $_ => 1 } qw/
  test_startup
  test_setup
  test_teardown
  test_shutdown
  /;

sub _tcm_run_test_control_method {
    my ( $self, $test_instance, $phase, $report_object ) = @_;

    $TEST_CONTROL_METHODS{$phase}
      or croak("Unknown test control method ($phase)");

    my %report_args = (
        name     => $phase,
        instance => (
              $report_object->isa('Test::Class::Moose::Report::Method')
            ? $report_object->instance
            : $report_object
        )
    );
    my $phase_method_report
      = Test::Class::Moose::Report::Method->new( \%report_args );

    my $set_meth = "set_${phase}_method";
    $report_object->$set_meth($phase_method_report);

    my $success;
    my $builder = $self->test_configuration->builder;

    # It'd be nicer to start and end immediately after we call
    # $test_instance->$phase but we can't guarantee that those calls would
    # happen inside the try block.
    $phase_method_report->_start_benchmark;

    try {
        my $num_tests = $builder->current_test;
        $test_instance->$phase($report_object);
        if ( $builder->current_test ne $num_tests ) {
            croak("Tests may not be run in test control methods ($phase)");
        }
        $success = 1;
    }
    catch {
        my $error = $_;
        my $class = $test_instance->test_class;
        $builder->diag("$class->$phase() failed: $error");
    };

    $phase_method_report->_end_benchmark;

    return $success;
}

sub _tcm_run_test_method {
    my ( $self, $test_instance, $test_method, $instance_report ) = @_;

    my $report = Test::Class::Moose::Report::Method->new(
        { name => $test_method, instance => $instance_report } );

    $instance_report->add_test_method($report);
    my $config = $self->test_configuration;

    my $builder = $config->builder;
    $test_instance->test_skip_clear;
    $self->_tcm_run_test_control_method(
        $test_instance,
        'test_setup',
        $report
    ) or fail "test_setup failed";
    my $num_tests;

    my $test_class = $test_instance->test_class;
    Test::Most::explain("$test_class->$test_method()");
    my $passed = $builder->subtest(
        $test_method,
        sub {
            if ( my $message = $test_instance->test_skip ) {
                $report->skipped($message);
                $builder->plan( skip_all => $message );
                return;
            }
            $report->_start_benchmark;

            my $old_test_count = $builder->current_test;
            try {
                $test_instance->$test_method($report);
                if ( $report->has_plan ) {
                    $builder->plan( tests => $report->tests_planned );
                }
            }
            catch {
                fail "$test_method failed: $_";
                $report->passed(0);
            };
            $num_tests = $builder->current_test - $old_test_count;

            $report->_end_benchmark;
            if ( $config->show_timing ) {
                my $time = $report->time->duration;
                $config->builder->diag( $report->name . ": $time" );
            }
        },
    );
    $report->passed($passed);

    $self->_tcm_run_test_control_method(
        $test_instance,
        'test_teardown',
        $report,
    ) or $report->passed( fail "test_teardown failed" );
    if ( !$report->is_skipped ) {
        $report->num_tests_run($num_tests);
        if ( !$report->has_plan ) {
            $report->tests_planned($num_tests);
        }
    }
    return $report;
}

sub test_classes {
    my $self = shift;

    if ( my $classes = $self->test_configuration->test_classes ) {
        if (@$classes) {    # ignore it if the array is empty
            return @$classes;
        }
    }

    my %metaclasses = Class::MOP::get_all_metaclasses();
    my @classes;
    foreach my $class ( keys %metaclasses ) {
        next if $class eq 'Test::Class::Moose';
        push @classes => $class if $class->isa('Test::Class::Moose');
    }

    if ( $self->test_configuration->randomize_classes ) {
        return shuffle(@classes);
    }
    return sort @classes;
}

1;

=for Pod::Coverage test_classes
