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

use Path::Tiny;

use Test::More 0.88;
use Test::Fatal;

use Cwd            ();
use File::Basename ();
use File::Spec     ();
use lib File::Spec->catdir( File::Basename::dirname( Cwd::abs_path __FILE__ ), 'lib' );

use Local::Test::TempDir qw(tempdir);

use App::Dotfiles::Runtime;
use App::Dotfiles::Module;

main();

sub main {
    my $class = 'App::Dotfiles::Module';

    my $home = tempdir();

    my $name    = 'test1';
    my $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

    my $obj   = new_ok( $class, [ runtime => $runtime, name => $name ] );
    my $obj_s = new_ok( $class, [ runtime => $runtime, name => $name, target_path_prefix => path('shift2/.SHIFT 2') ] );

    my $test_ws = path( $home, '.files', $name );
    $test_ws->mkpath();

    # empty module
    my $linkables = $obj->get_linkables(q{.});
    my $expected  = [];
    is_deeply( $linkables, $expected, 'an empty module returns no linkables' );

    $linkables = $obj_s->get_linkables(q{.});
    is_deeply( $linkables, $expected, '... target_path_prefix is ignored' );

    # only .git
    $test_ws->child('.git')->mkpath();

    $linkables = $obj->get_linkables(q{.});
    $expected  = [];
    is_deeply( $linkables, $expected, q{... a '.git' directory is ignored} );

    $linkables = $obj_s->get_linkables(q{.});
    is_deeply( $linkables, $expected, '... target_path_prefix is ignored' );

    # test.txt
    $test_ws->child('test.txt')->spew();

    $linkables = $obj->get_linkables(q{.});
    $expected  = [qw(test.txt)];
    is_deeply( $linkables, $expected, q{... a file is returned} );

    $linkables = $obj_s->get_linkables(q{.});
    is_deeply( $linkables, $expected, '... target_path_prefix is ignored' );

    my $exception = exception { $obj->get_linkables('test.txt') };
    isa_ok( $exception, 'App::Dotfiles::Error', 'get_linkables() throws an exception when run on a file' );
    like( $exception, "/ \QNot a directory: $test_ws\E /xsm", '... with correct message' );

    # dir1 and link1
    $test_ws->child('dir1')->mkpath();
    _symlink( $test_ws->child('dir1')->realpath(), $test_ws->child('link1')->realpath() );
    $exception = exception { $obj->get_linkables('test.txt') };
    isa_ok( $exception, 'App::Dotfiles::Error', 'get_linkables() throws an exception when run on a symlink' );
    like( $exception, "/ \QNot a directory: $test_ws\E /xsm", '... with correct message' );

    $linkables = [ sort @{ $obj->get_linkables(q{.}) } ];
    $expected  = [ sort qw(test.txt dir1 link1) ];
    is_deeply( $linkables, $expected, q{... a file, a dir and a symlink are returned} );

    $linkables = [ sort @{ $obj_s->get_linkables(q{.}) } ];
    is_deeply( $linkables, $expected, '... target_path_prefix is ignoed' );

    # source_path_prefix
    $obj = new_ok( $class, [ runtime => $runtime, name => $name, source_path_prefix => 'dir1' ] );

    $linkables = $obj->get_linkables(q{.});
    $expected  = [];
    is_deeply( $linkables, $expected, 'source_path_prefix to an empty dir' );

    $test_ws->child('dir1/shift1.txt')->spew();

    $linkables = $obj->get_linkables(q{.});
    $expected  = [qw(shift1.txt)];
    is_deeply( $linkables, $expected, 'source_path_prefix to a dir with a single file' );

    # source_path_prefix on file
    $obj       = new_ok( $class, [ runtime => $runtime, name => $name, source_path_prefix => path('dir1/shift1.txt') ] );
    $exception = exception { $obj->get_linkables(q{.}) };
    isa_ok( $exception, 'App::Dotfiles::Error', 'get_linkables() throws an exception when run with a source_path_prefix on a file' );
    like( $exception, "/ \QNot a directory: $test_ws\E /xsm", '... with correct message' );

    # source_path_prefix on a dir with perm 000
    $test_ws->child('dir2')->mkpath();
    _chmod( 0000, $test_ws->child('dir2') );

    $obj       = new_ok( $class, [ runtime => $runtime, name => $name, source_path_prefix => 'dir2' ] );
    $exception = exception { $obj->get_linkables(q{.}) };

    # allow Dist::Zilla to clean up the file
    _chmod( 0755, $test_ws->child('dir2') );

    note($exception);
    isa_ok( $exception, 'App::Dotfiles::Error', 'get_linkables() throws an exception when run with a source_path_prefix on a dir without permissions' );
    like( $exception, "/ \QUnable to read directory '$test_ws\E /xsm", '... with correct message' );

    #
    done_testing();

    exit 0;
}

sub _chmod {
    my $rc = chmod @_;
    BAIL_OUT("chmod @_: $!") if !$rc;
    return $rc;
}

sub _symlink {
    my ( $old_name, $new_name ) = @_;

    my $rc = symlink $old_name, $new_name;
    BAIL_OUT("symlink $old_name, $new_name: $!") if !$rc;
    return $rc;
}
