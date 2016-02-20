package Test::Events;

use strict;
use warnings;

use List::Util qw( pairs );
use Scalar::Util qw( blessed );
use Test::Deep qw( cmp_deeply );
use Test::More;

use Exporter qw( import );

our @EXPORT = 'is_events';

sub is_events {
    my $got = shift;

    is( scalar @{$got},
        ( scalar @_ ) / 2,
        'got expected number of events'
    );

    for my $pair ( pairs @_ ) {
        my ( $type, $attr ) = @{$pair};

        my $event = shift @{$got}
          or last;

        isa_ok( $event, 'Test2::Event::' . $type );
        if ( $type eq 'Subtest' ) {
            my @copy = @{$attr};
            _test_attr( $event, shift @copy );
            subtest(
                'results of subtest named ' . $event->name,
                sub { is_events( $event->subevents, @copy ) }
            );
        }
        else {
            _test_attr( $event, $attr );
        }
    }
}

sub _test_attr {
    my $obj  = shift;
    my $attr = shift;

    for my $k ( sort keys %{$attr} ) {
        my $expect = $attr->{$k};
        my $func
          = blessed($expect) && $expect->isa('Regexp')
          ? \&like
          : \&cmp_deeply;

        $func->(
            $obj->$k,
            $attr->{$k},
            "\$obj->$k",
        );
    }
}

1;

