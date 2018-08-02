package UseMissingSubclass;
use strict;
use warnings;

# Extending a Test class with a non-existing class must die

use Test::Class::Moose extends => 'This::Class::Does::Not::Exist';

1;
