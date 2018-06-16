#!perl

use 5.006;
use strict;
use warnings;

use Test::Fatal qw(dies_ok exception);
use Test::More 0.88;
use Test::TempDir::Tiny;

use App::Dotfiles::Runtime;
use App::Dotfiles::CLI::Command;

main();

sub main {
    my $class = 'App::Dotfiles::CLI::Command';

    my $home = tempdir();
    my $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

    #
    note('defaults');
    my $obj = new_ok( $class, [ runtime => $runtime ] );

    isa_ok( $obj->runtime, 'App::Dotfiles::Runtime', q{attribute 'runtime'} );

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
