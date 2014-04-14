package MyParallelTests;

use Moose;

extends 'Test::Class::Moose::Runner::Sequential';
with 'Test::Class::Moose::Role::Parallel';

1;
