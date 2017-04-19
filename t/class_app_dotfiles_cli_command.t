#!perl -T

use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::More;
use Test::TempDir::Tiny;

use App::Dotfiles::Runtime;
use App::Dotfiles::CLI::Command;

## no critic (RegularExpressions::RequireDotMatchAnything)
## no critic (RegularExpressions::RequireExtendedFormatting)
## no critic (RegularExpressions::RequireLineBoundaryMatching)

main();

sub main {
    my $class = 'App::Dotfiles::CLI::Command';

    my $home = tempdir();
    my $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

    #
    note('defaults');
    my $obj = new_ok( $class, [ runtime => $runtime ] );

    isa_ok( $obj->runtime, 'App::Dotfiles::Runtime', q{attribute 'runtime'} );
    is( $obj->stow_verbose, 1, q{attribute 'stow_verbose'} );

    #
    note('non-defaults');
    $obj = new_ok( $class, [ runtime => $runtime, stow_verbose => 0 ] );

    isa_ok( $obj->runtime, 'App::Dotfiles::Runtime', q{attribute 'runtime'} );
    is( $obj->stow_verbose, 0, q{attribute 'stow_verbose'} );
    like( exception { $obj->stow_verbose('abc') }, qr{stow_verbose is a read-only accessor}, '... is a read only accessor' );

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
