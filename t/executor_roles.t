use strict;
use warnings;

use Test2::V0;

use Test::Class::Moose::Runner;

{
    package My::Role;
    use namespace::autoclean;
    use Moose::Role;
}

my $runner = Test::Class::Moose::Runner->new(
    executor_roles => ['My::Role'],
);

ok( $runner->_executor->does('My::Role'),
    'executor roles are applied to executor object'
);

done_testing();
