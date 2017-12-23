package TestsFor::Todo;

use Test::Class::Moose bare => 1;

use Test::Builder;
use Test2::Tools::Basic qw( ok todo );
use Test2::Tools::Compare
  qw( array call end event filter_items F is match object T );

sub test_todo {
    my $self = shift;

    ok( 1, 'pre-todo' );
    todo(
        'not implemented',
        sub {
            ok( 0, 'in todo' );
        }
    );
    ok( 1, 'post-todo' );
}

sub test_todo_die1 {
    my $self = shift;

    ok( 1, 'pre-todo' );
    todo(
        'not implemented',
        sub {
            die 'in todo';
            ok( 0, 'in todo' );
        }
    );
    ok( 1, 'post-todo' );
}

sub test_todo_die2 {
    my $self = shift;

    ok( 1, 'pre-todo' );
    my $builder = Test::Builder->new;
    $builder->todo_start('not implemented');
    die 'in todo';
    ok( 0, 'in todo' );
    $builder->todo_end;
    ok( 1, 'post-todo' );
}

sub expected_test_events {
    event Subtest => sub {
        call name           => 'TestsFor::Todo';
        call pass           => F();
        call effective_pass => F();

        call subevents => array {
            filter_items {
                grep {
                         !$_->isa('Test2::AsyncSubtest::Event::Attach')
                      && !$_->isa('Test2::AsyncSubtest::Event::Detach')
                } @_;
            };

            event Plan => sub {
                call max => 3;
            };

            event Subtest => sub {
                call name           => 'test_todo';
                call pass           => T();
                call effective_pass => T();

                call subevents => array {
                    event Ok => sub {
                        call name           => 'pre-todo';
                        call pass           => T();
                        call effective_pass => T();
                    };

                    event Ok => sub {
                        call name           => 'in todo';
                        call pass           => F();
                        call effective_pass => T();
                    };

                    event Note => sub {
                        call message => match qr{^\n?Failed test};
                    };

                    event Ok => sub {
                        call name           => 'post-todo';
                        call pass           => T();
                        call effective_pass => T();
                    };

                    event Plan => sub {
                        call max => 3;
                    };
                    end();
                };
            };

            event Subtest => sub {
                call name           => 'test_todo_die1';
                call pass           => F();
                call effective_pass => F();

                call subevents => array {
                    event Ok => sub {
                        call name           => 'pre-todo';
                        call pass           => T();
                        call effective_pass => T();
                    };

                    event Exception => sub {
                        call error => match qr/in todo at .+/;
                    };

                    event Plan => sub {
                        call max => 1;
                    };
                    end();
                };
            };

            event Diag => sub {
                call message => match qr{^\n?Failed test};
            };

            event Subtest => sub {
                call name           => 'test_todo_die2';
                call pass           => F();
                call effective_pass => F();

                call subevents => array {
                    event Ok => sub {
                        call name           => 'pre-todo';
                        call pass           => T();
                        call effective_pass => T();
                    };

                    event Exception => sub {
                        call error => match qr/in todo at .+/;
                    };

                    event Plan => sub {
                        call max => 1;
                    };
                    end();
                };
            };

            event Diag => sub {
                call message => match qr{^\n?Failed test};
            };

            end();
        };
    };
}

sub expected_report {
    return (
        'TestsFor::Todo' => {
            is_skipped => F(),
            passed     => F(),
            instances  => {
                'TestsFor::Todo' => {
                    is_skipped => F(),
                    passed     => F(),
                    methods    => {
                        test_todo => {
                            is_skipped    => F(),
                            passed        => T(),
                            num_tests_run => 3,
                            tests_planned => 3,
                        },
                        test_todo_die1 => {
                            is_skipped    => F(),
                            passed        => F(),
                            num_tests_run => 0,
                            tests_planned => undef,
                        },
                        test_todo_die2 => {
                            is_skipped    => F(),
                            passed        => F(),
                            num_tests_run => 0,
                            tests_planned => undef,
                        },
                    },
                },
            },
        },
    );
}

1;
