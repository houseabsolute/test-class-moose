package Test::Class::Moose::Role;

# ABSTRACT: Test::Class::Moose for roles

use 5.10.0;
use Carp qw/carp croak cluck/;

use Test::Class::Moose::TagRegistry;
use Class::Load qw/try_load_class/;

our $NO_CAN_HAZ_ATTRIBUTES;
BEGIN {
    eval "use Sub::Attribute";
    unless($NO_CAN_HAZ_ATTRIBUTES = $@){
        eval <<'DECLARE_ATTRIBUTE';
        sub Tags : ATTR_SUB {
            my ( $class, $symbol, undef, undef, $data, undef, $file, $line ) = @_;

            my @tags;
            if ($data) {
                $data =~ s/^\s+//g;
                @tags = split /\s+/, $data;
            }

            if ( $symbol eq 'ANON' ) {
                die "Cannot tag anonymous subs at file $file, line $line\n";
            }

            my $method = *{ $symbol }{ NAME };

            {           # block for localising $@
                local $@;

                Test::Class::Moose::TagRegistry->add(
                    $class,
                    $method,
                    \@tags,
                );
                if ( $@ ) {
                    croak "Error in adding tags: $@";
                }
            }
        }
DECLARE_ATTRIBUTE
        $NO_CAN_HAZ_ATTRIBUTES = $@;
    }
}


sub import {
    my ( $class, %arg_for ) = @_;
    my $caller = caller;

    my $role_class = delete $arg_for{parameterized} ?
      'MooseX::Role::Parameterized' : 'Moose::Role';

    try_load_class( $role_class )
      or croak "Can't load base role class $role_class";

    my $preamble = <<"END";
package $caller;
use $role_class;
use Test::Most;

use strict;
use warnings;

use Carp;
use Data::Dumper;
END

    unless ($NO_CAN_HAZ_ATTRIBUTES) {
        $preamble .= "use Sub::Attribute;\n";
    }
    eval $preamble;
    unless ($NO_CAN_HAZ_ATTRIBUTES) {
        no strict "refs";
        *{"$caller\::Tags"} = \&Tags;
    }
}

1;

__END__

=head1 DESCRIPTION

If you need the functionality of L<Test::Class::Moose> to be available inside
of a role, this is the module to do that. This is how you can declare a TCM
role:

    package TestsFor::Basic::Role;

    use Test::Class::Moose::Role;

    sub test_in_a_role {
        my $test = shift;

        pass "This is picked up from role";
    }


    sub in_a_role_with_tags : Tags(first){
        fail "We should never see this test";
    }


    sub test_in_a_role_with_tags : Tags(second){
        pass "We should see this test";
    }

    1;

And to consume it:

    package TestsFor::Basic::WithRole;
    use Test::Class::Moose;

    with qw/TestsFor::Basic::Role/;

    sub test_in_withrole {
        pass "Got here";
    }

    1;

Or, if you want to use L<MooseX::Role::Parameterized> instead of
L<Moose::Role>:

    package TestsFor::Basic::Role;

    use Test::Class::Moose::Role parameterized => 1;

    parameter message => ( is => 'ro', default => "Picked up from role" );

    role {
        my $p = shift;
        method test_in_a_role => sub {
            pass $p->message;
        }
    }

And to consume this:

    package TestsFor::Basic::ParameterizedRole;
    use Test::Class::Moose;

    with 'TestsFor::Basic::Role' => {
        message => "This is picked up from a parameterized role"
    };

Note that this cannot be consumed into classes and magically make them into
test classes. You must still (at the present time) inherit from
C<Test::Class::Moose> to create a test suite.
