package Test::Class::Moose::Runner;

# ABSTRACT: Run Test::Class::Moose tests

use 5.10.0;
use Moose 2.0000;
use Carp;
use namespace::autoclean;

use Test::Class::Moose::Config;

has 'test_configuration' => (
    is  => 'ro',
    isa => 'Test::Class::Moose::Config',
);

has 'jobs' => (
    is      => 'ro',
    isa     => 'Int',
    default => 1,
);

has 'color_output' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has '_executor' => (
    is         => 'ro',
    init_arg   => undef,
    lazy_build => 1,
    handles    => [ 'runtests', 'test_classes', 'test_report' ],
);

my %config_attrs = map { $_->init_arg => 1}
    Test::Class::Moose::Config->meta->get_all_attributes;
around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $p = $class->$orig(@_);

    my %config_p = map { $config_attrs{$_} ? ( $_ => delete $p->{$_} ) : () }
        keys %{$p};

    $p->{test_configuration} ||= Test::Class::Moose::Config->new(%config_p);

    return $p;
};

sub _build__executor {
    my $self = shift;

    if ( $self->jobs == 1 ) {
        require Test::Class::Moose::Executor::Sequential;
        return Test::Class::Moose::Executor::Sequential->new(
            test_configuration => $self->test_configuration );
    }
    else {
        require Test::Class::Moose::Executor::Parallel;
        return Test::Class::Moose::Executor::Parallel->new(
            test_configuration => $self->test_configuration,
            jobs               => $self->jobs,
            color_output       => $self->color_output,
        );
    }
}

1;
