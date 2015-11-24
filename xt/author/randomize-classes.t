use strict;
use warnings;

use Test::More;

use Test::Class::Moose::Load 't/randomlib';
use Test::Class::Moose::Runner;

my $tcmr = Test::Class::Moose::Runner->new( randomize_classes => 1 );

TODO: {
    local $TODO = 'cannot guarantee that randomized class list is not ABCDE';

    # there is no "isnt_deeply", so string comparison instead.
    my $classes = join( q{}, $tcmr->test_classes );
    isnt( $classes, 'ABCDE', "$classes is not ABCDE" );
}

done_testing();
