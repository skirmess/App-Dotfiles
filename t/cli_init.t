#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;
use Test::TempDir::Tiny;

use File::Spec;
use File::Path qw(make_path);

use Git::Wrapper;

use Path::Tiny;

use Capture::Tiny qw(capture);

use App::Dotfiles::Runtime;
use App::Dotfiles::CLI::Command;

main();

sub main {
    my $home = tempdir();
    my $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

    my $obj = new_ok( 'App::Dotfiles::CLI::Command', [ runtime => $runtime ] );

    my $url = 'http://git.example.net/test.git';

    #
    my $config_path = File::Spec->catfile( $home, '.files', '.config' );
    note('~/.files/.config/.git exists but is not a Git repository');
    {
        make_path( File::Spec->catfile( $config_path, '.git' ) );

        my ( $stdout, $stderr, @result ) = capture {
            exception { $obj->run_init($url) }
        };
        like( $result[0], "/ \QDirectory '$home/.files/.config' exists but is not a valid Git directory\E /xsm", '... throws an exception when the config dir exists but is not a Git repository' );
        is( $stdout, q{}, '... prints nothing to stdout' );
        is( $stderr, q{}, '... and nothing to stderr' );
    }

    #
    note('~/.files/.config exists and is a Git repository');
    my $git = Git::Wrapper->new($config_path);
    {
        $git->init();

        my ( $stdout, $stderr, @result ) = capture {
            exception { $obj->run_init($url) }
        };
        like( $result[0], "/ \QConfig '.config' exists already\E /xsm", '... throws an error if the config dir exists and is a git repository' );
        is( $stdout, q{}, '... prints nothing to stdout' );
        is( $stderr, q{}, '... and nothing to stderr' );
    }

    #
    note('no modules.ini file in repository');

    $home = tempdir();
    $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

    my $remote_config = tempdir();
    $git = Git::Wrapper->new($remote_config);
    $git->init('-q');

    _touch( File::Spec->catfile( $remote_config, 'test.txt' ) );
    $git->config( 'user.email', 'test@example.net' );
    $git->config( 'user.name',  'Test User' );
    $git->add('test.txt');
    $git->commit( '-q', '-m', 'test' );

    $obj = new_ok( 'App::Dotfiles::CLI::Command', [ runtime => $runtime ] );

    {
        my ( $stdout, $stderr, @result ) = capture {
            exception { $obj->run_init($remote_config) }
        };
        like( $result[0], "/ \QMissing config file '$home/.files/.config/modules.ini\E /xsm", 'run_init() throws an error if the config repository contains no modules.ini file' );
        chomp $stdout;
        is( $stdout, q{Initializing config '.config'}, '... prints initialization message to stdout' );
        is( $stderr, q{}, '... and nothing to stderr' );
    }

    #
    note('empty modules.ini file in repository');
    $git->mv( 'test.txt', 'modules.ini' );
    $git->commit( '-q', '-m', 'test' );

    $home    = tempdir();
    $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );
    $obj     = new_ok( 'App::Dotfiles::CLI::Command', [ runtime => $runtime ] );

    ok( !-e File::Spec->catfile( $home, '.files', '.config', 'modules.ini' ), 'config repo does not exist' );
    {
        my ( $stdout, $stderr, @result ) = capture { $obj->run_init($remote_config) };
        is( $result[0], undef, 'returns undef if the config repository was cloned successfully' );
        my @stdout = split /\n/xsm, $stdout;
        chomp @stdout;
        is( $stdout[0], q{Initializing config '.config'},          '... prints inizializing message' );
        is( $stdout[1], q{No modules configured in 'modules.ini'}, '... prints no modules configured message' );
        is( $stderr,    q{},                                       '... and nothing to stderr' );
    }
    ok( -e File::Spec->catfile( $home, '.files', '.config', 'modules.ini' ), 'config repo does exist' );

    #
    note('modules.ini with two modules');

    my $repo1 = tempdir();
    my $git1  = Git::Wrapper->new($repo1);
    $git1->init('-q');
    _touch( File::Spec->catfile( $repo1, 'file1.txt' ) );
    make_path( File::Spec->catfile( $repo1, 'dir1' ) );
    _touch( File::Spec->catfile( $repo1, 'dir1', 'file1a.txt' ) );
    $git1->config( 'user.email', 'test@example.net' );
    $git1->config( 'user.name',  'Test User' );
    $git1->add( 'file1.txt', 'dir1' );
    $git1->commit( '-q', '-m', 'test' );

    my $repo2 = tempdir();
    my $git2  = Git::Wrapper->new($repo2);
    $git2->init('-q');
    _touch( File::Spec->catfile( $repo2, 'file2.txt' ) );
    make_path( File::Spec->catfile( $repo2, 'dir2' ) );
    _touch( File::Spec->catfile( $repo2, 'dir2', 'file2a.txt' ) );
    $git2->config( 'user.email', 'test@example.net' );
    $git2->config( 'user.name',  'Test User' );
    $git2->add( 'file2.txt', 'dir2' );
    $git2->commit( '-q', '-m', 'test' );

    _touch( File::Spec->catfile( $remote_config, 'modules.ini' ), <<"EOF");
[module1]
pull=$repo1

[module 2]
pull = $repo2
EOF
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
    {
        my ( $stdout, $stderr, @result ) = capture { $obj->run_init($remote_config) };
        is( $result[0], undef, 'returns undef if the config repository was cloned successfully' );
        my @stdout = split /\n/xsm, $stdout;
        chomp @stdout;
        is( shift @stdout, q{Initializing config '.config'}, '... prints initializing message to stdout' );
        is( pop @stdout,   q{Dotfiles updated successfully}, '... prints updated successfully message' );

        my @expected;
        my $repo_path = File::Spec->catfile( $home, '.files', 'module1' );
        push @expected, "Cloning repository '$repo1' into '$repo_path'";
        $repo_path = File::Spec->catfile( $home, '.files', 'module 2' );
        push @expected, "Cloning repository '$repo2' into '$repo_path'";

        push @expected,
          "Linking $home/dir1 to .files/module1/dir1",
          "Linking $home/dir2 to .files/module 2/dir2",
          "Linking $home/file1.txt to .files/module1/file1.txt",
          "Linking $home/file2.txt to .files/module 2/file2.txt";

        is_deeply( [ sort @stdout ], [ sort @expected ], '... prints cloning messages' );

        is( $stderr, q{}, '... and nothing to stderr' );

    }

    for my $file (@files) {
        ok( -e $file, "File '$file' exists now" );
    }

    #
    done_testing();

    exit 0;
}

sub _touch {
    my ( $file, @content ) = @_;

    path($file)->spew(@content) or BAIL_OUT("Cannot write file '$file': $!");

    return;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
