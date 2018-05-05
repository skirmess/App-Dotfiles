#!perl

use 5.006;
use strict;
use warnings;

use Path::Tiny;

use Test::More;
use Test::Fatal;
use Test::TempDir::Tiny;

use App::Dotfiles::Runtime;
use App::Dotfiles::Linker;

main();

sub main {
    my $class = 'App::Dotfiles::Linker';

    my $home = tempdir();

    my $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );
    my $obj = new_ok( $class, [ runtime => $runtime ] );

    # _read_first_link_and_realpath_nd
    $home = path($home);
    my $file = $home->child('file.txt');
    $file->spew();

    my $exception = exception { $obj->_read_first_link_and_realpath_nd($file) };
    isa_ok( $exception, 'App::Dotfiles::Error', '_read_first_link_and_realpath_nd() throws an exception if called on a file' );
    like( $exception, "/ \QFile '$file' is not a symlink\E /xsm", '... with the correct message' );

    $exception = exception { $obj->_read_first_link_and_realpath_nd('x') };
    isa_ok( $exception, 'App::Dotfiles::Error', '_read_first_link_and_realpath_nd() throws an exception if called with a relative path' );
    like( $exception, "/ \QFile 'x' is not absolute\E /xsm", '... with the correct message' );

    #
    note('relative link to file');
    my $link_rel = $home->child('link_rel');
    _symlink( 'file.txt', $link_rel );

    my $link_result = $obj->_read_first_link_and_realpath_nd($link_rel);
    is( $link_result, $file, 'resolves correctly' );

    #
    note('absolute link to file');
    my $link_abs = $home->child('link_abs');
    _symlink( $file, $link_abs );

    $link_result = $obj->_read_first_link_and_realpath_nd($link_abs);
    is( $link_result, $file, 'resolves correctly' );

    #
    note('absolute link to an absolute link to a file');
    my $link_abs_abs = $home->child('link_abs_abs');
    _symlink( $link_abs, $link_abs_abs );

    $link_result = $obj->_read_first_link_and_realpath_nd($link_abs_abs);
    is( $link_result, $link_abs, 'resolves correctly' );

    #
    note('absolute link to an relative link to a file');
    my $link_abs_rel = $home->child('link_abs_rel');
    _symlink( $link_rel, $link_abs_rel );

    $link_result = $obj->_read_first_link_and_realpath_nd($link_abs_rel);
    is( $link_result, $link_rel, 'resolves correctly' );

    #
    note('relative link to an absolute link to a file');
    my $link_rel_abs = $home->child('link_rel_abs');
    _symlink( 'link_abs', $link_rel_abs );

    $link_result = $obj->_read_first_link_and_realpath_nd($link_rel_abs);
    is( $link_result, $link_abs, 'resolves correctly' );

    #
    note('relative link to an relative link to a file');
    my $link_rel_rel = $home->child('link_rel_rel');
    _symlink( 'link_rel', $link_rel_rel );

    $link_result = $obj->_read_first_link_and_realpath_nd($link_rel_rel);
    is( $link_result, $link_rel, 'resolves correctly' );

    #
    note('absolute link to non-existing file');
    my $link_abs_non_existing = $home->child('link_abs_non_existing');
    my $non_existing_file_abs = $home->child('non/existing/file');
    _symlink( $non_existing_file_abs, $link_abs_non_existing );

    $link_result = $obj->_read_first_link_and_realpath_nd($link_abs_non_existing);
    is( $link_result, $non_existing_file_abs, 'resolves correctly' );

    #
    note('relative link to non-existing file');
    my $link_rel_non_existing = $home->child('link_rel_non_existing');
    _symlink( path('non/existing/file'), $link_rel_non_existing );

    $link_result = $obj->_read_first_link_and_realpath_nd($link_rel_non_existing);
    is( $link_result, $non_existing_file_abs, 'resolves correctly' );

    #
    note('absolute link to absolute link to non-existing file');
    my $link_abs_abs_non_existing = $home->child('link_abs_abs_non_existing');
    _symlink( $link_abs_non_existing, $link_abs_abs_non_existing );

    $link_result = $obj->_read_first_link_and_realpath_nd($link_abs_abs_non_existing);
    is( $link_result, $link_abs_non_existing, 'resolves correctly' );

    #
    note('absolute link to relative link to non-existing file');
    my $link_abs_rel_non_existing = $home->child('link_abs_rel_non_existing');
    _symlink( $link_rel_non_existing, $link_abs_rel_non_existing );

    $link_result = $obj->_read_first_link_and_realpath_nd($link_abs_rel_non_existing);
    is( $link_result, $link_rel_non_existing, 'resolves correctly' );

    #
    note('relative link to absolute link non-existing file');
    my $link_rel_abs_non_existing = $home->child('link_rel_abs_non_existing');
    _symlink( 'link_abs_non_existing', $link_rel_abs_non_existing );

    $link_result = $obj->_read_first_link_and_realpath_nd($link_rel_abs_non_existing);
    is( $link_result, $link_abs_non_existing, 'resolves correctly' );

    note('relative link to relative link non-existing file');
    my $link_rel_rel_non_existing = $home->child('link_rel_rel_non_existing');
    _symlink( 'link_rel_non_existing', $link_rel_rel_non_existing );

    $link_result = $obj->_read_first_link_and_realpath_nd($link_rel_rel_non_existing);
    is( $link_result, $link_rel_non_existing, 'resolves correctly' );

    #
    done_testing();

    exit 0;
}

sub _symlink {
    my ( $old_name, $new_name ) = @_;

    my $rc = symlink $old_name, $new_name;
    BAIL_OUT("symlink $old_name, $new_name: $!") if !$rc;
    return $rc;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
