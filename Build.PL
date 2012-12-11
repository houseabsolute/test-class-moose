use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Test::Class::Moose',
    license           => 'perl',
    dist_author       => q{Curtis "Ovid" Poe <ovid@cpan.org>},
    dist_version_from => 'lib/Test/Class/Moose.pm',
    build_requires    => {
        'Test::Most' => '0.25',
    },
    requires => {
        'Moose'                   => 0,
    },
    add_to_cleanup     => ['Test-Class-Moose-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
