#!perl
use strict;
use warnings;
use autodie;

use Test::More;
use Test::TempDir::Tiny;
use Test::Fatal;

use File::Spec;
use File::Path qw(make_path);

use Log::Any::Test;
use Log::Any qw($log);

use App::Dotfiles::Runtime;
use App::Dotfiles::CLI::Command;

## no critic (RegularExpressions::RequireDotMatchAnything)
## no critic (RegularExpressions::RequireExtendedFormatting)
## no critic (RegularExpressions::RequireLineBoundaryMatching)

main();

sub main {

    # untaint
    my ($home) = tempdir() =~ m{ (.*) }xsm;
    local ( $ENV{PATH} ) = $ENV{PATH} =~ m{ (.*) }xsm;

    my $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

    my $obj = new_ok( 'App::Dotfiles::CLI::Command', [ runtime => $runtime ] );

    $log->empty_ok('log is empty');

    # _stow
    is( $obj->_stow(), undef, '_stow() returns undef' );
    $log->contains_ok( qr{There are no packages to stow}, '... logs that there is nothing to stow.' );
    $log->empty_ok('... no more logs');

    #
    note('one empty package');
    my $test_module_path = File::Spec->catfile( $home, '.files', 'test' );
    ok( !-e $test_module_path, 'test module does not exist' );
    make_path($test_module_path);
    ok( -d $test_module_path, '... now it does (empty)' );

    is( $obj->_stow('test'), undef, q{stow('test') returns undef} );
    $log->contains_ok( qr{Planning 'stow' actions}, '... logs the planning phase' );
    $log->contains_ok( qr{Stowing modules test},    '... logs the stowing phase' );
    $log->empty_ok('... no more logs');

    # one non-empty package
    open my $fh, '>', File::Spec->catfile( $test_module_path, 'a.txt' );
    close $fh;

    ok( !-e File::Spec->catfile( $home, 'a.txt' ), 'a.txt does not exist in home dir' );
    is( $obj->_stow('test'), undef, q{stow('test') returns undef} );
    $log->contains_ok( qr{Planning 'stow' actions}, '... logs the planning phase' );
    $log->contains_ok( qr{Stowing modules test},    '... logs the stowing phase' );
    $log->empty_ok('... no more logs');
    ok( -l File::Spec->catfile( $home, 'a.txt' ), 'a.txt does now exist in home dir' );
    is( readlink File::Spec->catfile( $home, 'a.txt' ), File::Spec->catfile( '.files', 'test', 'a.txt' ), '... symlink' );

    #
    note('two non-empty packages');
    my $test_module_path2 = File::Spec->catfile( $home, '.files', 'test2' );
    make_path($test_module_path2);

    open $fh, '>', File::Spec->catfile( $test_module_path2, 'b.txt' );
    close $fh;

    ok( -l File::Spec->catfile( $home, 'a.txt' ), 'a.txt exists in home dir' );
    is( readlink File::Spec->catfile( $home, 'a.txt' ), File::Spec->catfile( '.files', 'test', 'a.txt' ), '... symlink' );
    ok( !-e File::Spec->catfile( $home, 'b.txt' ), 'b.txt does not exist' );
    is( $obj->_stow( 'test', 'test2' ), undef, q{stow('test', 'test2') returns undef} );
    $log->contains_ok( qr{Planning 'stow' actions},    '... logs the planning phase' );
    $log->contains_ok( qr{Stowing modules test test2}, '... logs the stowing phase' );
    $log->empty_ok('... no more logs');
    ok( -l File::Spec->catfile( $home, 'a.txt' ), 'a.txt exists as a symlink in home dir' );
    is( readlink File::Spec->catfile( $home, 'a.txt' ), File::Spec->catfile( '.files', 'test', 'a.txt' ), '... symlink' );
    ok( -l File::Spec->catfile( $home, 'b.txt' ), 'b.txt exists as a symlink in home dir' );
    is( readlink File::Spec->catfile( $home, 'b.txt' ), File::Spec->catfile( '.files', 'test2', 'b.txt' ), '... symlink' );

    #
    note('conflict');
    open $fh, '>', File::Spec->catfile( $home, '.files', 'test2', 'a.txt' );
    close $fh;

    $log->empty_ok('log is empty');
    like( exception { $obj->_stow( 'test', 'test2' ) }, qr{All stow operations aborted}, q{stow('test', 'test2') throws an error on conflict} );
    $log->contains_ok( qr{Planning 'stow' actions},                                                            '... logs the planning phase' );
    $log->contains_ok( qr{stowing 'test2' would cause conflicts},                                              '... logs the conflict' );
    $log->contains_ok( qr{existing target is stowed to a different package: a[.]txt => [.]files/test/a[.]txt}, '... logs the conflicting files' );
    $log->empty_ok('... no more logs');

    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
