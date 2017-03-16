use strict;
use warnings;

use Test2::Bundle::Extended;
use Test::Class::Moose::Load 't/randomlib';
use Test::Class::Moose::Runner;

my $tcmr = Test::Class::Moose::Runner->new( randomize_classes => 0 );

is( [ $tcmr->test_classes ],
    [qw( ClassA ClassB ClassC ClassD ClassE )],
    'got a sorted list of classes'
);

done_testing();
