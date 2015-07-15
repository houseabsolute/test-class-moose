use strict;
use warnings;

use Test::More;
use Test::Class::Moose::Load 't/randomlib';
use Test::Class::Moose::Runner;

my $tcmr = Test::Class::Moose::Runner->new( randomize_classes => 0 );

is_deeply(
    [ $tcmr->test_classes ],
    [qw( A B C D E )],
    'got a sorted list of classes'
);

done_testing();
