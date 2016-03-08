use strict;
use warnings;

use lib 'lib', 't/lib';

use Test2::API qw( intercept );
use Test2::Tools::Basic qw( done_testing );
use Test2::Tools::Compare qw( F T );
use Test::Reporting qw( test_report );

use Test::Class::Moose::Load qw(t/basiclib);
use Test::Class::Moose::Runner;

my $runner = Test::Class::Moose::Runner->new;

intercept {
    $runner->runtests;
};

my %expect = (
    is_parallel        => F(),
    num_tests_run      => 27,
    num_test_instances => 2,
    num_test_methods   => 9,
    classes            => {
        'TestsFor::Basic' => {
            is_skipped => F(),
            passed     => T(),
            instances  => {
                'TestsFor::Basic' => {
                    is_skipped => F(),
                    passed     => T(),
                    methods    => {
                        test_me => {
                            is_skipped    => F(),
                            passed        => T(),
                            num_tests_run => 4,
                            tests_planned => 4,
                        },
                        test_my_instance_name => {
                            is_skipped    => F(),
                            passed        => T(),
                            num_tests_run => 1,
                            tests_planned => 1,
                        },
                        test_reporting => {
                            is_skipped    => F(),
                            passed        => T(),
                            num_tests_run => 4,
                            tests_planned => 4,
                        },
                        test_this_baby => {
                            is_skipped    => F(),
                            passed        => T(),
                            num_tests_run => 3,
                            tests_planned => 3,
                        },
                    },
                },
            },
        },
        'TestsFor::Basic::Subclass' => {
            is_skipped => F(),
            passed     => T(),
            instances  => {
                'TestsFor::Basic::Subclass' => {
                    is_skipped => F(),
                    passed     => T(),
                    methods    => {
                        test_me => {
                            is_skipped    => F(),
                            passed        => T(),
                            num_tests_run => 1,
                            tests_planned => 1,
                        },
                        test_my_instance_name => {
                            is_skipped    => F(),
                            passed        => T(),
                            num_tests_run => 1,
                            tests_planned => 1,
                        },
                        test_reporting => {
                            is_skipped    => F(),
                            passed        => T(),
                            num_tests_run => 4,
                            tests_planned => 4,
                        },
                        test_this_baby => {
                            is_skipped    => F(),
                            passed        => T(),
                            num_tests_run => 4,
                            tests_planned => 4,
                        },
                        test_this_should_be_run => {
                            is_skipped    => F(),
                            passed        => T(),
                            num_tests_run => 5,
                            tests_planned => 5,
                        },
                    },
                },
            },
        },
    },
);

test_report( $runner->test_report, \%expect );

done_testing;

__END__

This is the code I used to generate the example in Test::Class::Moose::Report
(plus a little manual editing to move the time key to the top of each nested
hashref).

my $t = $report->timing_data;
delete $t->{class}{'TestsFor::Basic::Subclass'};
delete $t->{class}{'TestsFor::Basic'}{instance}{'TestsFor::Basic'}{method}{test_reporting};
delete $t->{class}{'TestsFor::Basic'}{instance}{'TestsFor::Basic'}{method}{test_this_baby};
use Devel::Dwarn; Dwarn _fudge($t);

sub _fudge {
    my $t = shift;

    use Data::Visitor::Callback;

    Data::Visitor::Callback->new(
        hash => sub {
            shift;
            my $h = shift;

            for my $k ( grep { exists $h->{$_} } qw( real system user ) ) {
                if ($h->{$k} ) {
                    $h->{$k} *= 10_000;
                }
                else {
                    $h->{$k} = $h->{real} * ($k eq 'system' ? 0.15 : 0.85);
                }
            }

            return $h;
        },
    )->visit($t);

    return $t;
}
