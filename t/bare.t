use strict;
use warnings;

use Test::More;
use Test::Warnings qw( warnings );

my $package = <<'EOF';
package TestFor::Bare;

use Test::Class::Moose bare => 1;
use Test::More;
use List::SomeUtils qw( any );
EOF

is_deeply(
    [ warnings { eval $package } ],
    [],
    'no warnings from using Test::Class::Moose with List::SomeUtils'
);

done_testing();
