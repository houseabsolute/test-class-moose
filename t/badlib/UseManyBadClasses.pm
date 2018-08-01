package UseManyBadClasses;
use strict;
use warnings;

# Extending a Test class with a lots of non-Test classes must die

use lib 't/badlib';
use Test::Class::Moose extends =>
  [ 'NoTestClass', 'Carp', 'Exporter', 'Cwd' ];

1;
