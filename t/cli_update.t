#!perl

use 5.006;
use strict;
use warnings;

use Carp;

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
    my $home    = tempdir();
    my $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

    my $obj = new_ok( 'App::Dotfiles::CLI::Command', [ runtime => $runtime ] );

    #
    note(' ~/.files does not exist');
    {
        my ( $stdout, $stderr, @result ) = capture {
            exception { $obj->run_update() }
        };

        isa_ok( $result[0], 'App::Dotfiles::Error::E_NO_CONFIG_REPOSITORY', 'run_update() throws an exception when the config dir does not exist.' );
        is( $stdout, q{}, '... prints nothing to stdout' );
        is( $stderr, q{}, '... and nothing to stderr' );
    }

    #
    note('~/.files/.config/.git exists but is not a Git repository');
    my $config_path = File::Spec->catfile( $home, '.files', '.config' );
    make_path( File::Spec->catfile( $config_path, '.git' ) );

    {
        my ( $stdout, $stderr, @result ) = capture {
            exception { $obj->run_update() }
        };
        like( $result[0], "/ \QDirectory '$home/.files/.config' exists but is not a valid Git directory\E /xsm", '... throws an axception when the config dir exists but is not a Git repository' );
        is( $stdout, q{}, '... prints nothing to stdout' );
        is( $stderr, q{}, '... and nothing to stderr' );
    }

    #
    note('~/.files/.config exists and is a Git repository');
    my $git = Git::Wrapper->new($config_path);
    $git->init();

    {
        my ( $stdout, $stderr, @result ) = capture {
            exception { $obj->run_update() }
        };
        chomp $stdout;
        isa_ok( $result[0], 'Git::Wrapper::Exception', '... throws an error if the config dir exists and is a Git repository but no remote repository is defined' );
        is( $stdout, q{Updating config '.config'}, '... prints the updating message' );
        is( $stderr, q{}, '... and nothing to stderr' );
    }

    #
    note('~/.files/.config exists and is a Git repository with a valid remote');
    my $repositories  = tempdir();
    my $remote_config = File::Spec->catfile( $repositories, 'config.git' );
    make_path($remote_config);

    my $git_remote = Git::Wrapper->new($remote_config);
    $git_remote->init( '-q', '--bare' );

    $git->config( 'user.email', 'test@example.net' );
    $git->config( 'user.name',  'Test User' );
    _touch( File::Spec->catfile( $config_path, 'test.txt' ) );
    $git->add('test.txt');
    $git->commit( '-q', '-m', 'test' );
    $git->remote( 'add', 'origin', "$repositories/config.git" );
    $git->push( '-q', '--set-upstream', 'origin', 'master' );

    {
        my ( $stdout, $stderr, @result ) = capture {
            exception { $obj->run_update() }
        };
        chomp $stdout;
        like( $result[0], "/ \QMissing config file '$home/.files/.config/modules.ini'\E /xsm", '... throws an exception if there is no modules.ini file' );
        is( $stdout, q{Updating config '.config'}, '... updating message' );
        is( $stderr, q{}, '... and nothing to stderr' );
    }

    #
    note('with a modules.ini file');
    _touch( File::Spec->catfile( $config_path, 'modules.ini' ) );
    $git->add( File::Spec->catfile( $config_path, 'modules.ini' ) );
    $git->commit( '-q', '-m', 'test' );

    {
        my ( $stdout, $stderr, @result ) = capture { $obj->run_update() };
        my @stdout = split /\n/xsm, $stdout;
        chomp @stdout;
        is( $result[0], undef,                                     'run_update() returns undef' );
        is( $stdout[0], q{Updating config '.config'},              '... updating message' );
        is( $stdout[1], q{No modules configured in 'modules.ini'}, q{... prints the warning that no modules are configured in 'modules.ini'} );
        is( @stdout,    2,                                         '... no more output' );
        is( $stderr,    q{},                                       '... and nothing to stderr' );

    }

    #
    note('Add a module to modules.ini and let it be cloned');
    my $test1_repo = File::Spec->catfile( $repositories, 'test1.git' );
    make_path($test1_repo);

    $git_remote = Git::Wrapper->new($test1_repo);
    $git_remote->init( '-q', '--bare' );

    # git fails if there is not a single commit
    make_path("${test1_repo}.workspace");
    $git_remote = Git::Wrapper->new("${test1_repo}.workspace");
    $git_remote->init('-q');
    _touch( File::Spec->catfile( "${test1_repo}.workspace", 'test.txt' ) );
    $git_remote->config( 'user.email', 'test@example.net' );
    $git_remote->config( 'user.name',  'Test User' );
    $git_remote->add('test.txt');
    $git_remote->commit( '-q', '-m', 'test' );
    $git_remote->remote( 'add', 'origin', $test1_repo );
    $git_remote->push( '-q', '--set-upstream', 'origin', 'master' );

    _touch(
        File::Spec->catfile( $config_path, 'modules.ini' ),
        "[test1]\n",
        "pull=$test1_repo\n",
    );

    $git->commit( '-q', '-a', '-m', 'test' );

    ok( !-e File::Spec->catfile( $home, '.files', 'test1' ), 'repo test1 does not exist' );

    note('clone');
    {
        my ( $stdout, $stderr, @result ) = capture { $obj->run_update() };
        my @stdout = split /\n/xsm, $stdout;
        chomp @stdout;
        is( $result[0], undef,                                                        'run_update() returns undef' );
        is( $stdout[0], q{Updating config '.config'},                                 '... updating message' );
        is( $stdout[1], "Cloning repository '$test1_repo' into '$home/.files/test1'", '... cloning message' );
        is( $stdout[2], "Linking $home/test.txt to .files/test1/test.txt",            '... linking output' );
        is( $stdout[3], q{Dotfiles updated successfully},                             '... updated successfully message' );
        is( @stdout,    4,                                                            '... no more output' );
        is( $stderr,    q{},                                                          '... and nothing to stderr' );
    }

    ok( -e File::Spec->catfile( $home, '.files', 'test1' ), 'repo test1 does now exist' );

    note('update');
    {
        my ( $stdout, $stderr, @result ) = capture { $obj->run_update() };
        my @stdout = split /\n/xsm, $stdout;
        chomp @stdout;
        is( $result[0], undef,                                           'run_update() returns undef' );
        is( $stdout[0], q{Updating config '.config'},                    '... updating message' );
        is( $stdout[1], q{Verifying 'remotes' config of module 'test1'}, '... verifying remotes message' );
        is( $stdout[2], q{Updating module 'test1'},                      '... other updating message' );
        is( $stdout[3], q{Dotfiles updated successfully},                '... updated successfully message' );
        is( @stdout,    4,                                               '... no more output' );
        is( $stderr,    q{},                                             '... and nothing to stderr' );
    }

    ok( -e File::Spec->catfile( $home, '.files', 'test1' ), 'repo test1 exists' );

    done_testing();

    exit 0;
}

sub _touch {
    my ( $file, @content ) = @_;

    path($file)->spew(@content) or BAIL_OUT("Cannot write file '$file': $!");

    return;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
