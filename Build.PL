use 5.10.0;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Test::Class::Moose',
    license           => 'perl',
    dist_author       => q{Curtis "Ovid" Poe <ovid@cpan.org>},
    dist_version_from => 'lib/Test/Class/Moose.pm',
    build_requires    => {},
    requires          => {
        'Moose'                => '2.0402',
        'namespace::autoclean' => '0.13',
        'Test::Most'           => '0.31',
        'Try::Tiny'            => '0.11',
    },
    meta_merge => {
        resources =>
          { repository => 'https://github.com/Ovid/test-class-moose', },
    },
    add_to_cleanup     => ['Test-Class-Moose-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
