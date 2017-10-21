#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::More;
use Test::TempDir::Tiny;

use File::Spec;

use App::Dotfiles::Runtime;

BEGIN {
    $ENV{PATH} = tempdir();
}

main();

sub main {
    my $home = tempdir();

    like( exception { App::Dotfiles::Runtime->new( home_path => $home ) }, "/ \QNo Git in PATH\E /xsm", 'new() throws an exception when there is no Git in PATH' );

    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
