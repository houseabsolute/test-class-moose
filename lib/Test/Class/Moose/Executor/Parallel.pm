package Test::Class::Moose::Executor::Parallel;

# ABSTRACT: Execute tests in parallel (parallelized by instance)

use 5.10.0;

our $VERSION = '0.79';

use Moose 2.0000;
use Carp;
use namespace::autoclean;
with 'Test::Class::Moose::Role::Executor';

# Needs to come before we load other test tools
use Test2::IPC;

use List::SomeUtils qw( none part );
use Parallel::ForkManager;
use Scalar::Util qw(reftype);
use TAP::Formatter::Color 3.29;
use Test2::API qw( test2_stack );
use Test2::AsyncSubtest 0.000018 ();
use Test::Class::Moose::AttributeRegistry;
use Test::Class::Moose::Report::Class;
use Try::Tiny;

has 'jobs' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has color_output => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has '_fork_manager' => (
    is       => 'ro',
    isa      => 'Parallel::ForkManager',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_fork_manager',
);

has '_subtests' => (
    traits   => ['Hash'],
    is       => 'bare',
    isa      => 'HashRef[Test2::AsyncSubtest]',
    init_arg => sub { {} },
    handles  => {
        _save_subtest  => 'set',
        _saved_subtest => 'get',
    },
);

has '_color' => (
    is      => 'ro',
    isa     => 'TAP::Formatter::Color',
    lazy    => 1,
    builder => '_build_color',
);

around _run_test_classes => sub {
    my $orig         = shift;
    my $self         = shift;
    my @test_classes = @_;

    my ( $seq, $par )
      = part { $self->_test_class_is_parallelizable($_) } @test_classes;

    $self->_run_test_classes_in_parallel($par);

    $self->$orig( @{$seq} )
      if $seq && @{$seq};

    return;
};

sub _test_class_is_parallelizable {
    my ( $self, $test_class ) = @_;

    return none {
        Test::Class::Moose::AttributeRegistry->method_has_tag(
            $test_class,
            $_,
            'noparallel'
        );
    }
    $self->_test_methods_for($test_class);
}

sub _run_test_classes_in_parallel {
    my $self         = shift;
    my $test_classes = shift;

    for my $test_class ( @{$test_classes} ) {
        my $subtest = Test2::AsyncSubtest->new(
            name          => $test_class,
            hub_init_args => { manual_skip_all => 1 },
        );
        my $id = $subtest->cleave;
        if ( my $pid = $self->_fork_manager->start ) {
            $self->_save_subtest( $pid => $subtest );
            next;
        }

        # This chunk of code only runs in child processes
        my $class_report;
        $subtest->attach($id);
        $subtest->run(
            sub {
                $class_report = $self->_run_test_class($test_class);
            }
        );
        $subtest->detach;
        $self->_fork_manager->finish( 0, \$class_report );
    }

    $self->_fork_manager->wait_all_children;
    test2_stack()->top->cull;

    return;
}

sub _build_fork_manager {
    my $self = shift;

    my $pfm = Parallel::ForkManager->new( $self->jobs );
    $pfm->run_on_finish(
        sub {
            my ( $pid, $class_report ) = @_[ 0, 5 ];

            try {
                $self->test_report->add_test_class( ${$class_report} );
            }
            catch {
                warn $_;
            };

            my $subtest = $self->_saved_subtest($pid);
            unless ($subtest) {
                warn
                  "Child process $pid ended but there is no active subtest for that pid!";
                return;
            }

            $subtest->finish;
        }
    );

    return $pfm;
}

around _run_test_method => sub {
    my $orig = shift;
    my $self = shift;

    my $method_report = $self->$orig(@_);

    # we're running under parallel testing, so rather than having
    # the code look like it's stalled, we'll output a dot for
    # every test method.
    my ( $color, $text )
      = $method_report->passed
      ? ( 'green', '.' )
      : ( 'red', 'X' );

    # The set_color() method from TAP::Formatter::Color is just ugly.
    if ( $self->color_output ) {
        $self->_color->set_color(
            sub { print STDERR shift, $text },
            $color,
        );
        $self->_color->set_color( sub { print STDERR shift }, 'reset' );
    }
    else {
        print STDERR $text;
    }

    return $method_report;
};

sub _build_color {
    return TAP::Formatter::Color->new;
}

1;

=for Pod::Coverage Tags Tests runtests
