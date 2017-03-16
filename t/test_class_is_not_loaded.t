use strict;
use warnings;

use Test2::Bundle::Extended;

use Test::Class::Moose::Runner;

like(
    dies {
        Test::Class::Moose::Runner->new(
            test_classes => ['Test::Class::Not::Loaded'],
          )->runtests
    },
    qr/\QFound the following class that is not a subclass of Test::Class::Moose: Test::Class::Not::Loaded (did you load this class?)/,
    'got expected error when trying to run a class which is not loaded'
);

{

    package Foo;
    sub foo { }
}

like(
    dies {
        Test::Class::Moose::Runner->new(
            test_classes => [ 'Test::Class::Not::Loaded', 'Foo' ],
          )->runtests
    },
    qr/\QFound the following classes that are not subclasses of Test::Class::Moose: Test::Class::Not::Loaded Foo (did you load these classes?)/,
    'got expected error when trying to run a class which is not loaded and one which is not a TCM subclass'
);

done_testing();
