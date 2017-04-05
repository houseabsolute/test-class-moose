package Test::Class::Moose::Deprecated;

# ABSTRACT: Managed deprecation warnings for Test::Class::Moose

use strict;
use warnings;
use namespace::autoclean;

use 5.10.0;

our $VERSION = '0.83';

use Package::DeprecationManager 0.16 -deprecations => {
    'Test::Class::Moose::Config::args' => '0.79',
};

1;

__END__

=pod

=head1 DESCRIPTION

    use Test::Class::Moose::Deprecated -api_version => $version;

=head1 FUNCTIONS

This module manages deprecation warnings for features that have been
deprecated in L<Test::Class::Moose>.

If you specify C<< -api_version => $version >>, you can use deprecated features
without warnings. Note that this special treatment is limited to the package
that loads C<Test::Class::Moose::Deprecated>.

=head1 DEPRECATIONS BY VERSION

The following features were deprecated in past versions and will now warn:

=head2 Test::Class::Moose::Config->args

This was deprecated in version 0.79.

=cut
