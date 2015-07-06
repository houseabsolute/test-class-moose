#!/usr/bin/env perl
use Test::Most 'bail';

use lib 't/loadlib/helpers';

require Test::Class::Moose::Load;

throws_ok(
    sub { Test::Class::Moose::Load->import('t/loadlib/tests') },
    qr{
          \QBareword "here" not allowed while "strict subs" in use at t\E.loadlib.helpers.Fail\Q.pm line 6\E
          .+
          \Qrequire LoadTests\E.Success.pm
      }sx,
    'failure to load module in Test::Class::Moose::Load includes a stack trace'
);

done_testing;
