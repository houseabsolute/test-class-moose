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

our $Indent = 0;

sub dump_events {
    my $events = shift;

    for my $event ( @{$events} ) {
        if ( $event->isa('Test2::Event::Subtest') ) {
            _d(     'Subtest(name: '
                  . $event->name
                  . ', pass:'
                  . $event->pass
                  . ') {' );
            {
                local $Indent = $Indent + 1;
                dump_events( $event->subevents );
            }
            _d('}');
        }
        elsif ( $event->isa('Test2::Event::Diag') ) {
            _d( 'Diag(' . _e( $event->message ) . ')' );
        }
        elsif ( $event->isa('Test2::Event::Note') ) {
            _d( 'Note(' . _e( $event->message ) . ')' );
        }
        elsif ( $event->isa('Test2::Event::Exception') ) {
            _d( 'Exception(' . $event->error . ')' );
        }
        elsif ( $event->isa('Test2::Event::Ok') ) {
            _d(     'Ok(pass:'
                  . $event->pass
                  . ( defined $event->name ? ', name:' . $event->name : q{} )
                  . ')' );
        }
        elsif ( $event->isa('Test2::Event::Plan') ) {
            _d( 'Plan(max:' . $event->max . ')' );
        }
        else {
            my ($type) = ( ref $event ) =~ /Test2::Event::(.+)/;
            _d($type);
        }
    }
}

sub _e {
    my $str = shift;
    $str =~ s/\n/\\n/g;
    $str =~ s/\r/\\r/g;
    return $str;
}

sub _d {
    my $i = q{ } x $Indent;
    diag( $i . $_[0] );
}

1;
