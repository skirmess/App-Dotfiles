#!perl
use strict;
use warnings;
use autodie;

use Path::Tiny;

use Test::More;
use Test::Fatal;
use Test::TempDir::Tiny;

use App::Dotfiles::Runtime;
use App::Dotfiles::Module;

## no critic (RegularExpressions::RequireDotMatchAnything)
## no critic (RegularExpressions::RequireExtendedFormatting)
## no critic (RegularExpressions::RequireLineBoundaryMatching)
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

main();

sub main {
    my $class = 'App::Dotfiles::Module';

    my $home = tempdir();

    my $name = 'test1';
    my $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

    my $obj = new_ok( $class, [ runtime => $runtime, name => $name ] );
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
    like( $exception, qr{Not a directory: $test_ws}, '... with correct message' );

    # dir1 and link1
    $test_ws->child('dir1')->mkpath();
    symlink $test_ws->child('dir1')->realpath(), $test_ws->child('link1')->realpath();
    $exception = exception { $obj->get_linkables('test.txt') };
    isa_ok( $exception, 'App::Dotfiles::Error', 'get_linkables() throws an exception when run on a symlink' );
    like( $exception, qr{Not a directory: $test_ws}, '... with correct message' );

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
    $obj = new_ok( $class, [ runtime => $runtime, name => $name, source_path_prefix => path('dir1/shift1.txt') ] );
    $exception = exception { $obj->get_linkables(q{.}) };
    isa_ok( $exception, 'App::Dotfiles::Error', 'get_linkables() throws an exception when run with a source_path_prefix on a file' );
    like( $exception, qr{Not a directory: $test_ws}, '... with correct message' );

    # source_path_prefix on a dir with perm 000
    $test_ws->child('dir2')->mkpath();
    chmod 0000, $test_ws->child('dir2');

    $obj = new_ok( $class, [ runtime => $runtime, name => $name, source_path_prefix => 'dir2' ] );
    $exception = exception { $obj->get_linkables(q{.}) };
    note($exception);
    isa_ok( $exception, 'App::Dotfiles::Error', 'get_linkables() throws an exception when run with a source_path_prefix on a dir without permissions' );
    like( $exception, qr{Unable to read directory '$test_ws}, '... with correct message' );

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
