use strict;
use warnings;

use FindBin qw( $Bin );
use lib "$Bin/loadlib/helpers";

use Test2::V0;
require Test::Class::Moose::Load;

like(
    dies { Test::Class::Moose::Load->import("$Bin/loadlib/tests") },
    qr{
          \QBareword "here" not allowed while "strict subs" in use at \E.+.loadlib.helpers.Fail\Q.pm line 6\E
          .+
          \Qrequire LoadTests\E.Success.pm
      }sx,
    'failure to load module in Test::Class::Moose::Load includes a stack trace'
);

done_testing;
