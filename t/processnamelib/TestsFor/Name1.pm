package TestsFor::Name1;

use Test::Class::Moose;

sub test_process_name {
    my $package = __PACKAGE__;
    like( $0, qr/$package/, '$0 contains package name' );
}

1;
