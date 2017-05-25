#!perl
use strict;
use warnings;
use autodie;

use Test::More;
use Test::Fatal;
use Test::TempDir::Tiny;

use Capture::Tiny qw(capture);

use App::Dotfiles::Runtime;
use App::Dotfiles::CLI::Command;

main();

sub main {
    my $home = tempdir();
    my $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

    my $obj = new_ok( 'App::Dotfiles::CLI::Command', [ runtime => $runtime ] );

    my ( $stdout, $stderr, @result ) = capture { $obj->run_help() };
    is( $result[0], undef, '... returns undef' );

    # don't test stdout, it might contain strange output from Pod::Usage because $0 is this test script
    is( $stderr, q{}, '... and nothing to stderr' );

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
