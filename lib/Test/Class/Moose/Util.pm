package Test::Class::Moose::Util;

use strict;
use warnings;

use Test2::API qw( context );

use Exporter qw( import );

our @EXPORT_OK = qw( context_do );

sub context_do (&;@) {
    my $code = shift;
    my @args = @_;

    my $ctx = context( level => 0 );

    my $want = wantarray;

    my @out;
    my $ok = eval {
        if ($want) {
            @out = $code->( $ctx, @args );
        }
        elsif ( defined($want) ) {
            $out[0] = $code->( $ctx, @args );
        }
        else {
            $code->( $ctx, @args );
        }
        1;
    };
    my $err = $@;

    $ctx->release;

    die $err unless $ok;

    return @out if $want;
    return $out[0] if defined $want;
    return;
}

1;
