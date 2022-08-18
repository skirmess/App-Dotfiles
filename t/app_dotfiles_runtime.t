#!perl

# vim: ts=4 sts=4 sw=4 et: syntax=perl
#
# Copyright (c) 2017-2022 Sven Kirmess
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use 5.006;
use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;

use Cwd            ();
use File::Basename ();
use File::Spec     ();
use lib File::Spec->catdir( File::Basename::dirname( Cwd::abs_path __FILE__ ), 'lib' );

use Local::Test::TempDir qw(tempdir);

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
