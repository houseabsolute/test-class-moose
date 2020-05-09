use strict;
use warnings;

use FindBin qw( $Bin );
use lib "$Bin/lib", "$Bin/badlib";

use Test2::V0;

# This test verifies the error handling when a TCM class extends a
# non-TCM subclass. All this happens at compile time, so the usual
# exception testing is not applicable. The modules get a directory of
# their own in t/badlib to make sure that no other tests pick them up
# with TCM::Load - which would die, because these modules *are*
# invalid.

my $error;

eval 'use ParentExtendsTCM bare => 1;';
is( $@, q{}, 'subclassing works with valid parent class' );

is_bad_parent(
    'ParentDoesNotExtendTCM',
    ['DoesNotExtendTCM'],
    'single parent that is not a TCM class'
);

is_bad_parent(
    'ManyParentsDoNotExtendTCM',
    [ 'DoesNotExtendTCM', 'Carp', 'Exporter', 'Cwd' ],
    'multiple parents that are not TCM classes'
);

is_bad_parent(
    'ParentDoesNotExist',
    ['This::Class::Does::Not::Exist'],
    'single parent that does not exist'
);

sub is_bad_parent {
    my $class   = shift;
    my $parents = shift;
    my $desc    = shift;

    eval "use $class bare => 1;";
    my $error = $@;

    my $base_pattern = join '\b.*?\b', @{$parents};
    my $n_classes    = scalar @{$parents};

    like(
        $error,
        qr/\b$class\b  # Bogus module
                   .*?\b$base_pattern\b      # Base classes
                   .*?\bTest::Class::Moose\b # Required parent
                   .*?$class/x,    # Bogus module
        "error message mentions $n_classes base class(es) - $desc"
    );
}

done_testing;
