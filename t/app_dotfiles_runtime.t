#!perl

use 5.006;
use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;
use Test::TempDir::Tiny;

use File::Spec;
use Path::Tiny;

use App::Dotfiles::Runtime;

main();

sub main {
    my $home = File::Spec->catfile( tempdir(), 'does_not_exit' );

    note('home_path is undef');
    like( exception { App::Dotfiles::Runtime->new( home_path => undef ) }, "/ \QHome directory is not specified\E /xsm", 'new() throws an exception if the home directory is not specified' );

    note('home_path is undef');
    like( exception { App::Dotfiles::Runtime->new( home_path => q{} ) }, "/ \QHome directory is not specified\E /xsm", 'new() throws an exception if the home directory is the empty string' );

    note('home directory does not exist');
    like( exception { App::Dotfiles::Runtime->new( home_path => $home ) }, "/ \QHome directory '$home' does not exist\E /xsm", 'new() throws an exception if the home directory does not exist' );

    note('home directory is not a directory');
    _touch( File::Spec->catfile($home) );
    like( exception { App::Dotfiles::Runtime->new( home_path => $home ) }, "/ \QHome directory '$home' is not a directory\E /xsm", 'new() throws an exception if the home directory is not a directory' );

    done_testing();

    exit 0;

}

sub _touch {
    my ( $file, @content ) = @_;

    path($file)->spew(@content) or BAIL_OUT("Cannot write file '$file': $!");

    return;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
