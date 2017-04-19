#!perl
use strict;
use warnings;
use autodie;

use Test::More;
use Test::Fatal;
use Test::TempDir::Tiny;

use Log::Any::Test;
use Log::Any qw($log);

use App::Dotfiles::Runtime;
use App::Dotfiles::CLI::Command;

main();

sub main {
    my $home = tempdir();
    my $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

    my $obj = new_ok( 'App::Dotfiles::CLI::Command', [ runtime => $runtime ] );

    is( $obj->run_help(), undef, 'run_help() returns undef' );
    $log->empty_ok('... log is empty');

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
