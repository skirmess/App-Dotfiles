#!perl -T

use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::More;
use Test::TempDir::Tiny;

use File::Spec;

use App::Dotfiles::Runtime;

## no critic (RegularExpressions::RequireDotMatchAnything)
## no critic (RegularExpressions::RequireExtendedFormatting)
## no critic (RegularExpressions::RequireLineBoundaryMatching)

main();

sub main {

    # untaint;
    my ($home) = File::Spec->catfile( tempdir(), 'does_not_exit' ) =~ m{ (.*) }xsm;

    note('home_path is undef');
    like( exception { App::Dotfiles::Runtime->new( home_path => undef ) }, qr{Home directory is not specified}, 'new() throws an exception if the home directory is not specified' );

    note('home_path is undef');
    like( exception { App::Dotfiles::Runtime->new( home_path => q{} ) }, qr{Home directory is not specified}, 'new() throws an exception if the home directory is the empty string' );

    note('home directory does not exist');
    like( exception { App::Dotfiles::Runtime->new( home_path => $home ) }, qr{Home directory '$home' does not exist}, 'new() throws an exception if the home directory does not exist' );

    note('home directory is not a directory');
    open my $fh, '>', File::Spec->catfile($home);
    close $fh;
    like( exception { App::Dotfiles::Runtime->new( home_path => $home ) }, qr{Home directory '$home' is not a directory}, 'new() throws an exception if the home directory is not a directory' );

    done_testing();

    exit 0;

}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
