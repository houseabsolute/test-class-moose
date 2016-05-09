package Test::Class::Moose::Load;

# ABSTRACT: Load L<Test::Class::Moose> classes automatically.

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.72';

use File::Find;
use File::Spec;

# Override to get your own filter
sub is_test_class {
    my ( $class, $file, $dir ) = @_;

    # By default, we only care about .pm files
    if ( $file =~ /\.pm$/ ) {
        return 1;
    }
    return;
}

my %Added_to_INC;

sub _load {
    my ( $class, $file, $dir ) = @_;

    $file =~ s{\.pm$}{};    # remove .pm extension
    $file =~ s{\\}{/}g;     # to make win32 happy
    $dir =~ s{\\}{/}g;      # to make win32 happy
    $file =~ s/^$dir//;
    my $_package = join '::' => grep $_ => File::Spec->splitdir($file);

    # untaint that puppy!
    my ($package) = $_package =~ /^([[:word:]]+(?:::[[:word:]]+)*)$/;

    # Filter out bad classes (mainly this means things in .svn and similar)
    return unless defined $package;

    unshift @INC => $dir unless $Added_to_INC{$dir}++;

    {
        local $SIG{__DIE__} = sub {
            undef $SIG{__DIE__};
            require Carp;
            local $Carp::CarpLevel = $Carp::CarpLevel + 1;
            Carp::confess(@_);
        };

        # either "require" it or "use" it with no import list. Otherwise, this
        # module will inherit from Test::Class::Moose and break everything.
        eval "use $package ()";    ## no critic
    }
    die $@ if $@;
}

sub import {
    my ( $class, @directories ) = @_;

    foreach my $dir (@directories) {
        $dir = File::Spec->catdir( split '/', $dir );
        find(
            {   no_chdir => 1,
                wanted   => sub {
                    my @args = ( $File::Find::name, $dir );
                    if ( $class->is_test_class(@args) ) {
                        $class->_load(@args);
                    }
                },
            },
            $dir
        );
    }
}

1;

__END__

=head1 SYNOPSIS

 use Test::Class::Moose::Load qw(t/tests t/lib);
 Test::Class::Moose->runtests;

=head1 EXPORT

None.

=head1 DESCRIPTION

Note: This helper module was blatantly stolen from L<Test::Class::Load>.
However, since your author is the person who originally wrote that code, he
doesn't feel too bad.

Without a loader, you would have to manually load each test class in your test
file. This would look something like this:

 #!/usr/bin/perl -T

 use strict;
 use warnings;

 use Test::Class::Moose::Runner;

 use lib 't/tests';

 use MyTest::Foo;
 use MyTest::Foo::Bar;
 use MyTest::Foo::Baz;

 Test::Class::Moose::Runner->runtests;

This causes a problem, though.  When you're writing a test class, it's easy to
forget to add it to the helper script.  Then you run your huge test suite and
see that all tests pass, even though you don't notice that it didn't run your
new test class.  Or you delete a test class and you forget to remove it from
the helper script.

L<Test::Class::Moose::Load> automatically finds and loads your test classes
for you. There is no longer a need to list them individually.

=head1 BASIC USAGE

Using L<Test::Class::Moose::Load> is as simple as this:

 #!/usr/bin/perl -T

 use strict;
 use warnings;

 use Test::Class::Moose::Runner;
 use Test::Class::Moose::Load 't/tests';

 Test::Class::Moose::Runner->new(\%args)->runtests;

That will search through all files in the C<t/tests> directory and
automatically load anything which ends in C<.pm>. You should only put test
classes in those directories.

If you have test classes in more than one directory, that's OK. Just list all
of them in the import list.

 use Test::Class::Moose::Load qw<
   t/customer
   t/order
   t/inventory
 >;
 Test::Class::Moose::Runner->runtests;

=head1 ADVANCED USAGE

Here's some examples of advanced usage of L<Test::Class::Moose::Load>.

=head2 FILTER LOADED CLASSES

You can redefine the filtering criteria, that is, decide what classes are
picked up and what others are not. You do this simply by subclassing
L<Test::Class::Moose::Load> overriding the C<is_test_class()> method. You
might want to do this to only load modules which inherit from
L<Test::Class::Moose>, or anything else for that matter.

=over 4

=item B<is_test_class>

  $is_test_class = $class->is_test_class( $file, $directory )

Returns true if C<$file> in C<$directory> should be considered a test class
and be loaded by L<Test::Class::Moose::Load>. The default filter simply
returns true if C<$file> ends with C<.pm>

=back

For example:

  use strict;
  use warnings;

  package My::Loader;
  use base qw( Test::Class::Moose::Load );

  # Overriding this selects what test classes
  # are considered by T::C::Load
  sub is_test_class {
      my ( $class, $file, $dir ) = @_;

      # return unless it's a .pm (the default)
      return unless $class->SUPER::is_test_class( $file, $dir );

      # and only allow .pm files with "Good" in their filename
      return $file =~ m{Good};
  }

  1;

=head2 CUSTOMIZING TEST RUNS

One problem with this style of testing is that you run I<all> of the tests
every time you need to test something.  If you want to run only one test
class, it's problematic.  The easy way to do this is to change your helper
script by deleting the C<runtests> call:

 #!/usr/bin/perl -T

 use strict;
 use warnings;

 use Test::Class::Moose::Load 't/tests';

Then, just make sure that all of your test classes inherit from your own base
class which runs the tests for you.  It might looks something like this:

 package My::Test::Class::Moose;

 use strict;
 use warnings;

 use Test::Class::Moose::Runner;

 use base 'Test::Class::Moose';

 INIT { Test::Class::Moose::Runner->new->runtests } # here's the magic!

 1;

Then you can run an individual test class by using the C<prove> utility, tell
it the directory of the test classes and the name of the test package you wish
to run:

 prove -lv -It/tests Some::Test::Class::Moose

You can even automate this by binding it to a key in C<vim>:

 noremap ,t  :!prove -lv -It/tests %<CR>

Then you can just type C<,t> ('comma', 'tee') and it will run the tests for
your test class or the tests for your test script (if you're using a
traditional L<Test::More> style script).

Of course, you can still run your helper script with C<prove>, C<make test> or
C<./Build test> to run all of your test classes.

If you do that, you'll have to make sure that the C<-I> switches point to your
test class directories.

=head1 SECURITY

L<Test::Class::Moose::Load> is taint safe.  Because we're reading the class
names from the directory structure, they're marked as tainted when running
under taint mode.  We use the following ultra-paranoid bit of code to untaint
them. Please file a bug report if this is too restrictive.

 my ($package) = $_package =~ /^([[:word:]]+(?:::[[:word:]]+)*)$/;

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-class-load@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Class-Load>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 ACKNOWLEDGMENTS

Thanks to David Wheeler for the idea and Adrian Howard for
L<Test::Class::Moose>.
