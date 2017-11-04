package Test::Class::Moose::Util;

use strict;
use warnings;

our $VERSION = '0.89';

use Test2::API qw( context );

use Exporter qw( import );

our @EXPORT_OK = qw( context_do );

# This is identical to the version in Test2::API except we set level to 0
# rather than 1.
sub context_do (&;@) {
    my $code = shift;
    my @args = @_;

    my $ctx = context( level => 0 );

    my $want = wantarray;

    my @out;
    my $ok = eval {
        $want ? @out
          = $code->( $ctx, @args )
          : defined($want) ? $out[0]
          = $code->( $ctx, @args )
          : $code->( $ctx, @args );
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

# ABSTRACT: Internal utilities

__END__

=for Pod::Coverage context_do
