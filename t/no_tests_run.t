use strict;
use warnings;

use Test2::V0;

use Test2::API qw( intercept );
use Test::Class::Moose::Runner;

{
    package TestFor::Empty;

    use strict;
    use warnings;

    use Test::Class::Moose;

    sub test_startup {
        $_[0]->test_skip('for some reason');
    }

    sub test_foo {
        ok(1);
    }
}

my $runner
  = Test::Class::Moose::Runner->new( test_classes => ['TestFor::Empty'] );
intercept { $runner->runtests };

my $report = $runner->test_report;

is( $report->num_tests_run, 0, 'num_tests_run returns 0, not undef' );

done_testing();

