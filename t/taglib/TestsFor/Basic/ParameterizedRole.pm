package TestsFor::Basic::ParameterizedRole;

use Class::Load qw/ try_load_class /;

our $mrp_available;
BEGIN { $mrp_available = try_load_class( 'MooseX::Role::Parameterized' ) }

use Test::Class::Moose::Role parameterized => $mrp_available;

if ( $mrp_available ) {
    parameter( message => ( is => 'ro', default => "Picked up from role" ));
    role( sub {
        my $p = shift;

        method(
          test_in_a_parameterizedrole => sub {
            pass $p->message;
          }
        );
    })
} else {
    diag "MooseX::Role::Parameterized not available. Skipping this role";
}


1;
