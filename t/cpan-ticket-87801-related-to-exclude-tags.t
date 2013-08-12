package TestFor;
use lib 'lib';
use Test::Class::Moose;

sub test_1 : Tags( ALL 001 ){
  ok(1, 'Test 1')
};

sub test_2 : Tags( ALL 002 ){
  ok(1, 'Test 1')
};

sub test_3 : Tags( ALL 003 ){
  ok(1, 'Test 1')
};

package main;
use lib 'lib';
use Test::Most;
use Data::Dumper;


my $test_suite = Test::Class::Moose->new( 
  include_tags => ['ALL'],
  exclude_tags => ['001', '002' ] 
);

my @test_methods = TestFor->new( $test_suite->test_configuration->args )->test_methods;

eq_or_diff \@test_methods,['test_3'],"exclude_tags excludes both '001','002' tags and only test_3 is tested";

#$test_suite->runtests;
done_testing;
