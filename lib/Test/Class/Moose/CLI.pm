package Test::Class::Moose::CLI;

# ABSTRACT: Use this in your tcm.t script for a drop-in runner tool

use 5.010000;

our $VERSION = '0.98';

use Moose 2.0000;
use Carp;
use namespace::autoclean;

with 'Test::Class::Moose::Role::CLI';

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

    # In a t/tcm.t file ...
    use Test::Class::Moose::CLI;

    Test::Class::Moose::CLI->new_with_options->run;

    # From the command line ...
    $> prove -lv t/tcm.t :: --classes TestFor::Foo --classes TestFor::Bar --tags quick --tags db --jobs 8

=head1 DESCRIPTION

This class provides support for passing various L<Test::Class::Moose::Config>
options via the command line.

It is entirely implemented by the L<Test::Class::Moose::Role::CLI> role, which
you can use in your own class to provide your own custom test runner.

=head1 COMMAND LINE OPTIONS

This class allows you to pass the following command-line options:

=head2 --classes

This should be the full name of one a class that you want to run (rather than
running classes).

You can also pass a path to a single class. Any leading C<t/lib/> part of the
path will be stripped, and the rest will be transformed from a path to a
module name.

Finally, you can pass a path to a directory. It will be searched for F<.pm>
files and each of those files will be loaded as a test class.

You can pass this option more than once.

=head2 --methods

The name of a method that you want to run. You can pass this option more than
once.

This will actually be turned into a regex like C<qr/^(?:foo|bar)$/>. It will
be matched against all classes that are being run.

=head2 --exclude-methods

The name of a method that you do not want to run. You can pass this option
more than once. This is turned into a regex just like C<--methods>.

=head2 --tags

The name of one or more test method tags that you want to include. Only test
method matching these tags will be run.

=head2 --exclude-tags

The name of one or more test method tags that you want to exclude. Any test
methods matching these tags will be ignored.

=head2 --parallel-progress and --no-parallel-progress

Show a progress indicator when running tests in parallel. Defaults to true.

=head2 --color and --no-color

Enable/disable color for the parallel progress output. Defaults to true.

=head2 --jobs

The number of jobs to run. Defaults to 1.

=head2 --randomize-methods

If true, methods for each class will be run in a random order. Defaults to
false.

=head2 --randomize-classes

If true, classes will be run in a random order. Defaults to false.

=head2 --set-process-name

If true, the process name (C<$0>) will be updated to include the name of each
test class as the class is being run.

=head2 --statistics

If true, this will output some extra statistics info as diagnostic output at
the end of the run. Defaults to false unless C<--use-environment> is true and
the C<HARNESS_IS_VERBOSE> environment variable is also true.

=head2 --show-timing

If true, this will output some extra timing info as diagnostic output at the
end of the run. Defaults to false unless C<--use-environment> is true and the
C<HARNESS_IS_VERBOSE> environment variable is also true.

=head2 --runner-class

The name of the runner class to use. Defaults to
L<Test::Class::Moose::Runner>. This class will be loaded when creating the
runner if it is not already loaded.

=head2 --test-lib-dirs

This should be the path to a directory containing test classes. The path can
be relative to the project root (F<t/lib>) or absolute. If you do not pass
this argument it will default to F<t/lib>.

You can pass this option more than once if you'd like to include multiple test
directories.

=head2 --timing-data-file

If this is passed, the value returned by C<<
Test::Class::Moose::Report->timing_data >> plus some other information will be
encoded as JSON and stored in this file. The exact data stored looks like:

    {
         process_name => $0,
         start_time   => $epoch_time
         timing       => \%timing_data_from_report,
    }

=head1 LOADING TEST CLASSES

If you pass classes with the C<--classes> option, only these classes will be
loaded. Otherwise all classes under F<t/lib> will be loaded.

=cut
