package UseBadSubclass;
use strict;
use warnings;

# Extending a Test class with a non-Test class must die

use lib 't/badlib';
use Test::Class::Moose extends => 'NoTestClass';

1;
