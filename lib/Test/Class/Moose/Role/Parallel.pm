package Test::Class::Moose::Role::Parallel;

# ABSTRACT: run tests in parallel

use Moose::Role;
use Parallel::ForkManager;
use Test::Class::Moose::TagRegistry;

has 'jobs' => (
    is      => 'ro',
    isa     => 'Int',
    default => 1,
);

has '_current_schedule' => (
    is        => 'rw',
    isa       => 'HashRef',
    predicate => '_schedule_set',
);

has '_need_orig_schedule' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

around 'BUILDARGS' => sub {
    my $orig    = shift;
    my $self    = shift;
    my %arg_for = ref $_[0] ? %{ $_[0] } : @_;
    my $jobs    = delete $arg_for{jobs};

    my $result = $self->$orig(%arg_for);
    $result->{jobs} = $jobs if $jobs;
    return $result;
};

around 'runtests' => sub {
    my $orig = shift;
    my $self = shift;

    my $jobs = $self->jobs;
    return $self->$orig if $jobs < 2;

    my ( $sequential, @jobs ) = $self->schedule;

    my $fork = Parallel::ForkManager->new($jobs);

    foreach my $schedule (@jobs) {
        my $pid = $fork->start and next;
        $self->_current_schedule($schedule);
        $self->$orig;
        $fork->finish;
    }
    $fork->wait_all_children;

    if ($sequential) {
        $self->_current_schedule($sequential);
        $self->$orig;
    }
};

around 'test_classes' => sub {
    my $orig = shift;
    my $self = shift;
    if ( $self->jobs < 2 or not $self->_schedule_set ) {
        return $self->$orig;
    }
    return sort keys %{ $self->_current_schedule };
};

around 'test_methods' => sub {
    my $orig         = shift;
    my $self         = shift;
    my @test_methods = $self->$orig;
    if ( $self->jobs < 2 or not $self->_schedule_set ) {
        return @test_methods;
    }
    my $methods_for_jobs = $self->_current_schedule->{ $self->test_class }
      or return;
    return grep { $methods_for_jobs->{$_} } @test_methods;
};

sub schedule {
    my $self = shift;
    my $jobs = $self->jobs;
    my @schedule;

    my $current_job = 0;
    foreach my $test_class ( $self->test_classes ) {
        my $test_instance
          = $test_class->new( $self->test_configuration->args );
        foreach my $method ( $test_instance->test_methods ) {
            $schedule[$current_job] ||= {};
            $schedule[$current_job]{$test_class}{$method} = 1;
            $current_job++;
            $current_job = 0 if $current_job >= $jobs;
        }
    }
    use Data::Dumper::Simple;
    $Data::Dumper::Indent   = 1;
    $Data::Dumper::Sortkeys = 1;
    print STDERR Dumper(@schedule);
    return undef, @schedule;
}

1;
__END__

=head1 SYNOPSIS

 package TestsFor::Some::Class;
 use Test::Class::Moose;
 with 'Test::Class::Moose::Role::Parallel';

 sub test_constructor {
     my $test  = shift;

     my $class = $test->class_name;             # Some::Class
     can_ok $class, 'new';                      # Some::Class is already loaded
     isa_ok my $object = $class->new, $class;   # and can be used as normal
 }

=head1 DESCRIPTION

This role allows you to automatically C<use> the classes your test class is
testing, providing the name of the class via the C<class_name> attribute.
Thus, you don't need to hardcode your class names.

=head1 PROVIDES

=head2 C<class_name>

Returns the name of the class you're testing. As a side-effect, the first time
it's called it will attempt to C<use> the class being tested.

=head2 C<get_class_name_to_use>

This method strips the leading section of the package name, up to and
including the first C<::>, and returns the rest of the name as the name of the
class being tested. For example, if your test class is named
C<Tests::Some::Person>, the name C<Some::Person> is returned as the name of
the class to use and test. If your test class is named
C<IHateTestingThis::Person>, then C<Person> is the name of the class to be
used and tested.

If you don't like how the name is calculated, you can override this method in
your code.

Warning: Don't use L<Test::> as a prefix. There are already plenty of modules
in that namespace and you could accidentally cause a collision.

=head1 RATIONALE

The example from our synopsis looks like this:

 package TestsFor::Some::Class;
 use Test::Class::Moose;
 with 'Test::Class::Moose::Role::AutoUse';

 sub test_constructor {
     my $test  = shift;

     my $class = $test->class_name;             # Some::Class
     can_ok $class, 'new';                      # Some::Class is already loaded
     isa_ok my $object = $class->new, $class;   # and can be used as normal
 }

Without this role, it would often look like this:

 package TestsFor::Some::Class;
 use Test::Class::Moose;
 use Some::Class;

 sub test_constructor {
     my $test  = shift;

     can_ok 'Some::Class', 'new';
     isa_ok my $object = 'Some::Class'->new, 'Some::Class';
 }

That's OK, but there are a couple of issues here.

First, if you need to rename your class, you must change this name repeatedly.
With L<Test::Class::Moose::Role::AutoUse>, you only rename the test class name
to correspond to the new class name and you're done.

The first problem is not very serious, but the second problem is. Let's say
you have a C<Person> class and then you create a C<Person::Employee> subclass.
Your test subclass might look like this:

 package TestsFor::Person::Employee;

 use Test::Class::Moose extends => "TestsFor::Person";

 # insert tests here

Object-oriented tests I<inherit> their parent class tests. Thus,
C<TestsFor::Person::Employee> will inherit the
C<TestsFor::Person->test_constructor()> method. Except as you can see in our
example above, we've B<hardcoded> the class name, meaning that we won't be
testing our code appropriately. The code using the
L<Test::Class::Moose::Role::AutoUse> role doesn't hardcode the classname (at
least, it shouldn't), so when we call the inherited
C<TestsFor::Person::Employee->test_constructor()> method, it constructs a
C<TestsFor::Person::Employee> object, not a C<TestsFor::Person> object.

Some might argue that this is a strawman and we should have done this:

 package TestsFor::Some::Class;
 use Test::Class::Moose;
 use Some::Class;

 sub class_name { 'Some::Class' }

 sub test_constructor {
     my $test  = shift;

     my $class = $test->class_name;             # Some::Class
     can_ok $class, 'new';                      # Some::Class is already loaded
     isa_ok my $object = $class->new, $class;   # and can be used as normal
 }

Yes, that's correct. We should have done this, except that now it's almost
identical to the AutoUse code, except that the first time you forget to C<use>
the class in question, you'll be unhappy. Why not automate this?

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-class-moose at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Class-Moose>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Class::Moose

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Class-Moose>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Class-Moose>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Class-Moose>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Class-Moose/>

=back

=cut

1;
