package Test::Class::Moose::Role;

# ABSTRACT: Test::Class::Moose for roles

use 5.10.0;
use Carp qw/carp croak cluck/;

use Test::Class::Moose::TagRegistry;

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


    my $preamble = <<"END";
package $caller;
use Moose::Role;
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
    croak($@) if $@;
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

Note that this cannot be consumed into classes and magically make them into
test classes. You must still (at the present time) inherit from
C<Test::Class::Moose> to create a test suite.
