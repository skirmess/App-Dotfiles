#!perl
use strict;
use warnings;
use autodie;

use Test::More;
use Test::Fatal;
use Test::TempDir::Tiny;

use File::Spec;
use File::Path qw(make_path);

use Git::Wrapper;

use Log::Any::Test;
use Log::Any qw($log);

use App::Dotfiles::Runtime;
use App::Dotfiles::CLI::Command;

## no critic (RegularExpressions::RequireDotMatchAnything)
## no critic (RegularExpressions::RequireExtendedFormatting)
## no critic (RegularExpressions::RequireLineBoundaryMatching)

main();

sub main {
    my $home = tempdir();
    my $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

    my $obj = new_ok( 'App::Dotfiles::CLI::Command', [ runtime => $runtime ] );

    my $url = 'http://git.example.net/test.git';

    #
    note('~/.files/.config/.git exists but is not a Git repository');
    my $config_path = File::Spec->catfile( $home, '.files', '.config' );
    make_path( File::Spec->catfile( $config_path, '.git' ) );

    like( exception { $obj->run_init($url) }, qr{Directory '$home/[.]files/[.]config' exists but is not a valid Git directory}, '... throws an exception when the config dir exists but is not a Git repository' );
    $log->empty_ok('... log is empty');

    #
    note('~/.files/.config exists and is a Git repository');
    my $git = Git::Wrapper->new($config_path);
    $git->init();

    like( exception { $obj->run_init($url) }, qr{Config '[.]config' exists already}, '... throws an error if the config dir exists and is a git repository' );
    $log->empty_ok('... no more logs');

    #
    note('no modules.ini file in repository');

    $home = tempdir();
    $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

    my $remote_config = tempdir();
    $git = Git::Wrapper->new($remote_config);
    $git->init('-q');

    open my $fh, '>', File::Spec->catfile( $remote_config, 'test.txt' );
    close $fh;
    $git->config( 'user.email', 'test@example.net' );
    $git->config( 'user.name',  'Test User' );
    $git->add('test.txt');
    $git->commit( '-q', '-m', 'test' );

    $obj = new_ok( 'App::Dotfiles::CLI::Command', [ runtime => $runtime ] );

    like( exception { $obj->run_init($remote_config) }, qr{Missing config file '$home/[.]files/[.]config/modules[.]ini'}, 'run_init() throws an error if the config repository contains no modules.ini file' );
    $log->contains_ok(q{Initializing config '.config'});
    $log->empty_ok('... no more logs');

    #
    note('empty modules.ini file in repository');
    $git->mv( 'test.txt', 'modules.ini' );
    $git->commit( '-q', '-m', 'test' );

    $home    = tempdir();
    $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );
    $obj     = new_ok( 'App::Dotfiles::CLI::Command', [ runtime => $runtime ] );

    ok( !-e File::Spec->catfile( $home, '.files', '.config', 'modules.ini' ), 'config repo does not exist' );
    is( $obj->run_init($remote_config), undef, 'returns undef if the config repository was cloned successfully' );
    ok( -e File::Spec->catfile( $home, '.files', '.config', 'modules.ini' ), 'config repo does exist' );
    $log->contains_ok(q{Initializing config '.config'});
    $log->contains_ok(q{No modules configured in 'modules.ini'});
    $log->empty_ok('... no more logs');

    #
    note('modules.ini with two modules');

    my $repo1 = tempdir();
    my $git1  = Git::Wrapper->new($repo1);
    $git1->init('-q');
    open $fh, '>', File::Spec->catfile( $repo1, 'file1.txt' );
    close $fh;
    make_path( File::Spec->catfile( $repo1, 'dir1' ) );
    open $fh, '>', File::Spec->catfile( $repo1, 'dir1', 'file1a.txt' );
    close $fh;
    $git1->config( 'user.email', 'test@example.net' );
    $git1->config( 'user.name',  'Test User' );
    $git1->add( 'file1.txt', 'dir1' );
    $git1->commit( '-q', '-m', 'test' );

    my $repo2 = tempdir();
    my $git2  = Git::Wrapper->new($repo2);
    $git2->init('-q');
    open $fh, '>', File::Spec->catfile( $repo2, 'file2.txt' );
    close $fh;
    make_path( File::Spec->catfile( $repo2, 'dir2' ) );
    open $fh, '>', File::Spec->catfile( $repo2, 'dir2', 'file2a.txt' );
    close $fh;
    $git2->config( 'user.email', 'test@example.net' );
    $git2->config( 'user.name',  'Test User' );
    $git2->add( 'file2.txt', 'dir2' );
    $git2->commit( '-q', '-m', 'test' );

    open $fh, '>', File::Spec->catfile( $remote_config, 'modules.ini' );
    print {$fh} <<"EOF";
[module1]
pull=$repo1

[module 2]
pull = $repo2
EOF
    close $fh;
    $git->add('modules.ini');
    $git->commit( '-q', '-m', 'test' );

    $home    = tempdir();
    $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );
    $obj     = new_ok( 'App::Dotfiles::CLI::Command', [ runtime => $runtime ] );

    my @files = (
        File::Spec->catfile( $home, '.files', '.config', 'modules.ini' ),

        File::Spec->catfile( $home, '.files', 'module1', 'file1.txt' ),
        File::Spec->catfile( $home, '.files', 'module1', 'dir1', 'file1a.txt' ),
        File::Spec->catfile( $home, 'file1.txt' ),
        File::Spec->catfile( $home, 'dir1', 'file1a.txt' ),

        File::Spec->catfile( $home, '.files', 'module 2', 'file2.txt' ),
        File::Spec->catfile( $home, '.files', 'module 2', 'dir2', 'file2a.txt' ),
        File::Spec->catfile( $home, 'file2.txt' ),
        File::Spec->catfile( $home, 'dir2', 'file2a.txt' ),
    );

    for my $file (@files) {
        ok( !-e $file, "File '$file' does not exist" );
    }
    is( $obj->run_init($remote_config), undef, 'returns undef if the config repository was cloned successfully' );
    for my $file (@files) {
        ok( -e $file, "File '$file' exists now" );
    }
    $log->contains_ok(q{Initializing config '.config'});

    my $repo_path = File::Spec->catfile( $home, '.files', 'module1' );
    $log->contains_ok("Cloning repository '$repo1' into '$repo_path'");

    $repo_path = File::Spec->catfile( $home, '.files', 'module 2' );
    $log->contains_ok("Cloning repository '$repo2' into '$repo_path'");

    $log->contains_ok(q{Dotfiles updated successfully});
    $log->empty_ok('... no more logs');

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
