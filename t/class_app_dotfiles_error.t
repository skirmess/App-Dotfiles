#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::More;

use App::Dotfiles::Error;

main();

sub main {

    my $exception = exception { App::Dotfiles::Error->throw('test 1 2 3') };
    isa_ok( $exception, 'App::Dotfiles::Error' );
    is( $exception, "test 1 2 3\n", 'correct error message' );

    $exception = exception { App::Dotfiles::Error->throw(q{}) };
    isa_ok( $exception, 'App::Dotfiles::Error' );
    is( $exception, "\n", 'empty error message' );

    $exception = exception { App::Dotfiles::Error->throw() };
    isa_ok( $exception, 'App::Dotfiles::Error' );
    is( $exception, "\n", 'no error message' );

    $exception = exception { App::Dotfiles::Error::E_NO_CONFIG_REPOSITORY->throw('test 1 2 3') };
    isa_ok( $exception, 'App::Dotfiles::Error::E_NO_CONFIG_REPOSITORY' );
    isa_ok( $exception, 'App::Dotfiles::Error' );
    is( $exception, "test 1 2 3\n", 'correct error message' );

    $exception = exception { App::Dotfiles::Error::E_REPOSITORY_IS_DIRTY->throw('test 1 2 3') };
    isa_ok( $exception, 'App::Dotfiles::Error::E_REPOSITORY_IS_DIRTY' );
    isa_ok( $exception, 'App::Dotfiles::Error' );
    is( $exception, "test 1 2 3\n", 'correct error message' );

    $exception = exception { App::Dotfiles::Error::E_USAGE->throw('test 1 2 3') };
    isa_ok( $exception, 'App::Dotfiles::Error::E_USAGE' );
    isa_ok( $exception, 'App::Dotfiles::Error' );
    is( $exception, "test 1 2 3\n", 'correct error message' );

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
