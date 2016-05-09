package TestsFor::Name1;

use Test::Class::Moose;

my %startup;

sub test_startup {
    my $package = __PACKAGE__;
    if ( $0 =~ /$package - test_startup/ ) {
        $startup{ok} = 1;
    }
    else {
        $startup{ok}   = 0;
        $startup{diag} = $0;
    }
}

my %setup;

sub test_setup {
    my $package = __PACKAGE__;
    if ( $0 =~ /$package - test_process_name - test_setup/ ) {
        $setup{ok} = 1;
    }
    else {
        $setup{ok}   = 0;
        $setup{diag} = $0;
    }
}

sub test_process_name {
    ok( $startup{ok}, '$0 contains control method name for test_startup' )
      or diag("Got [$startup{diag}]");

    ok( $setup{ok}, '$0 contains control method name for test_setup' )
      or diag("Got [$setup{diag}]");

    my $package = __PACKAGE__;
    like(
        $0, qr/$package - test_process_name/,
        '$0 contains package and method name'
    );
}

1;
