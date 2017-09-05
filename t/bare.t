use strict;
use warnings;

use Test2::V0;
use Test::Warnings qw( warnings :no_end_test );

my $package = <<'EOF';
package TestFor::Bare;

use Test::Class::Moose bare => 1;
use Test::More;
use List::SomeUtils qw( any );
EOF

is( [ warnings { eval $package } ],
    array { end(); },
    'no warnings from using Test::Class::Moose with List::SomeUtils'
);

my $package2 = <<'EOF';
package TestFor::Bare;

use Test::Class::Moose::Role bare => 1;
use Test::More;
use List::SomeUtils qw( any );
EOF

is( [ warnings { eval $package2 } ],
    array { end(); },
    'no warnings from using Test::Class::Moose::Role with List::SomeUtils'
);

done_testing();
