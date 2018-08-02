use strict;
use warnings;

use lib 't/lib', 't/badlib';

use Test2::V0;

# This test verifies the error handling when a TCM class extends a
# non-TCM subclass. All this happens at compile time, so the usual
# exception testing is not applicable. The modules get a directory of
# their own in t/badlib to make sure that no other tests pick them up
# with TCM::Load - which would die, because these modules *are*
# invalid.

my $error;

# Verify that the error isn't triggered for correct subclassing
eval 'use UseSubclass bare => 1;';
$error = $@ // q{};
is( $error, q{}, 'Subclassing works fine' );

# Verify that a class extending a non-test class can't be loaded
try_load( 'UseBadSubclass', 'NoTestClass' );

# Verify that a class extending many non-test classes can't be loaded
try_load( 'UseManyBadClasses', 'NoTestClass', 'Carp', 'Exporter', 'Cwd' );

# Verify that a class extending a nonexisting class can't be loaded
try_load( 'UseMissingSubclass', 'This::Class::Does::Not::Exist' );

sub try_load {
    my ( $class, @base_classes ) = @_;
    eval "use $class bare => 1;";
    my $error        = $@ // q{};
    my $base_pattern = join( '\b.*?\b', @base_classes );
    my $n_classes    = scalar @base_classes;
    like(
        $error, qr/\b$class\b  # Bogus module
                   .*?\b$base_pattern\b      # Base classes
                   .*?\bTest::Class::Moose\b # Required parent
                   .*?$class/x,    # Bogus module
        "Error message provides $n_classes base class(es)"
    );
}

done_testing;
