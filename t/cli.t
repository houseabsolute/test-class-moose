use strict;
use warnings;

use Test2::Bundle::Extended;

use File::Spec;
use File::Temp qw( tempdir );
use JSON qw( decode_json );
use Test2::API qw( intercept );
use Test::Class::Moose::CLI;

{

    package FakeRunner;

    use Moose;

    has args => ( is => 'ro' );

    around BUILDARGS => sub {
        my $orig = shift;
        my $self = shift;

        return { args => $self->$orig(@_) };
    };

    sub runtests { }

    sub test_report { FakeReport->new }
}

{

    package FakeReport;

    use Moose;

    sub timing_data {
        return {
            timing => 'data',
        };
    }
}

{
    my @tests = (
        [   'empty args',
            {},
            {}
        ],
        [   '--classes',
            { classes      => [qw( Foo Bar Baz )] },
            { test_classes => [qw( Foo Bar Baz )] }
        ],
        [   '--tags',
            { tags         => [qw( Big DB )] },
            { include_tags => [qw( Big DB )] },
        ],
        [   '--methods',
            { methods => [qw( foo bar baz )] },
            { include => qr/^(?:foo|bar|baz)$/ }
        ],
        [   '--exclude-methods',
            { 'exclude-methods' => [qw( foo bar baz )] },
            { exclude           => qr/^(?:foo|bar|baz)$/ },
        ],
        [   '--color',
            { color        => 1 },
            { color_output => 1 }
        ],
    );

    for my $test (@tests) {
        my ( $name, $argv, $expect ) = @{$test};

        subtest $name => sub {
            local @ARGV = _fake_argv($argv);

            my $runner = Test::Class::Moose::CLI->new_with_options(
                runner_class => 'FakeRunner' )->run;
            is( $runner->args,
                $expect,
                'got expected Runner args from CLI options'
            );
        };
    }
}

subtest 'timing data file' => sub {
    my $dir = File::Temp->newdir;
    my $file = File::Spec->catfile( $dir, 'timing.json' );

    my $time = time;
    local @ARGV = ( '--timing-data-file', $file );
    Test::Class::Moose::CLI->new_with_options( runner_class => 'FakeRunner' )
      ->run;

    ok( -f $file,
        'timing data file exists'
    );
    open my $fh, '<', $file or die $!;
    my $data = decode_json(
        do { local $/; <$fh> }
    );
    close $fh or die $!;

    is( $data,
        hash {
            field process_name => $0;
            field start_time =>
              validator( sub { defined $_ && $_ >= $time } );
            field timing => { timing => 'data' };
        },
        'timing data contains expected JSON data'
    );
};

subtest 'classes as paths' => sub {
    local @ARGV = (
        '--classes', 't/lib/TestFor/MyApp/Model.pm',
        '--classes', 't/lib/TestFor/MyApp/Controller.pm'
    );
    my $runner = Test::Class::Moose::CLI->new_with_options(
        runner_class => 'FakeRunner' )->run;
    is( $runner->args->{test_classes},
        [qw( TestFor::MyApp::Model TestFor::MyApp::Controller )],
        '--classes as paths are converted to class names'
    );
};

{

    package Test::CLI;

    use Moose;

    with 'Test::Class::Moose::Role::CLI';

    sub _test_lib_dirs { return ('t/clilib') }
}

subtest 'classes from CLI are loaded' => sub {
    local @ARGV = ( '--classes', 'Foo' );
    intercept { Test::CLI->new_with_options->run };
    ok( $Foo::LOADED,  'Foo class was loaded' );
    ok( !$Bar::LOADED, 'Bar class was not loaded' );

    local @ARGV = ( '--classes', 't/clilib/Bar.pm' );
    intercept { Test::CLI->new_with_options->run };
    ok( $Bar::LOADED, 'Bar class was loaded' );
};

{

    package My::CLI;

    use Moose;

    with 'Test::Class::Moose::Role::CLI';

    has before_count       => ( is => 'rw' );
    has load_classes_count => ( is => 'rw' );
    has after_count        => ( is => 'rw' );

    sub _munge_class { 'FR::' . $_[1] }

    sub _test_lib_dirs {qw( t/lib t/testlib )}

    sub _load_classes {
        $_[0]->load_classes_count( ( $_[0]->load_classes_count // 0 ) + 1 );
    }

    sub _before_run {
        $_[0]->before_count( ( $_[0]->before_count // 0 ) + 1 );
    }

    sub _after_run { $_[0]->after_count( ( $_[0]->after_count // 0 ) + 1 ) }
}

subtest 'role extension methods' => sub {
    local @ARGV
      = (
        qw( --classes Foo --classes Bar --classes t/lib/Baz.pm --classes t/testlib/Quux.pm )
      );
    my $cli = My::CLI->new_with_options( runner_class => 'FakeRunner' );
    my $runner = $cli->run;
    is( $runner->args->{test_classes},
        [ 'FR::Foo', 'FR::Bar', 'FR::Baz', 'FR::Quux' ],
        'class names were munged and paths were converted to classes'
    );
    is( $cli->before_count,
        1,
        '_before_run method was called once'
    );
    is( $cli->load_classes_count,
        1,
        '_load_classes method was called once'
    );
    is( $cli->after_count,
        1,
        '_after_run method was called once'
    );
};

done_testing();

sub _fake_argv {
    my $args = shift;

    my @argv;
    for my $key ( keys %{$args} ) {
        my $val = $args->{$key};

        my $option = '--' . $key;
        if ( ref $val ) {
            push @argv, map { $option => $_ } @{$val};
        }
        else {
            push @argv, $option => $val;
        }
    }

    return @argv;
}
