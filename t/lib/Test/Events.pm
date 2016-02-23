package Test::Events;

use strict;
use warnings;

use Exporter qw( import );

our @EXPORT = qw( test_events );

use Test2::Bundle::Extended;

sub test_events {
    my $events = shift;
    my $expect = shift;

    is( $events, $expect )
      or _diag_exception_events($events);

    return;
}

sub _diag_exception_events {
    my $events = shift;

    for my $e ( @{$events} ) {
        if ( $e->isa('Test2::Event::Subtest') ) {
            _diag_exception_events( $e->subevents );
        }
        elsif ( $e->isa('Test2::Event::Exception') ) {
            diag( $e->error );
        }
    }
}
