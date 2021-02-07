package ParentExtendsTCM;

use strict;
use warnings;
use namespace::autoclean;

# Extending a Test class with a TCM class must work

use lib 't/badlib';
use Test::Class::Moose extends => 'TestClass';

1;
