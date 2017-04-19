#!perl
use strict;
use warnings;
use autodie;

use Carp;

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

sub _print {
    my ( $fh, @args ) = @_;

    print {$fh} @args or croak qq{$!};
    return;
}

sub main {
    my $home = tempdir();
    my $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

    my $obj = new_ok( 'App::Dotfiles::CLI::Command', [ runtime => $runtime ] );

    #
    note(' ~/.files does not exist');
    isa_ok( exception { $obj->run_update() }, 'App::Dotfiles::Error::E_NO_CONFIG_REPOSITORY', 'run_update() throws an exception when the config dir does not exist.' );
    $log->empty_ok('... log is empty');

    #
    note('~/.files/.config/.git exists but is not a Git repository');
    my $config_path = File::Spec->catfile( $home, '.files', '.config' );
    make_path( File::Spec->catfile( $config_path, '.git' ) );

    like( exception { $obj->run_update() }, qr{Directory '$home/[.]files/[.]config' exists but is not a valid Git directory}, '... throws an axception when the config dir exists but is not a Git repository' );
    $log->empty_ok('... log is empty');

    #
    note('~/.files/.config exists and is a Git repository');
    my $git = Git::Wrapper->new($config_path);
    $git->init();

    isa_ok( exception { $obj->run_update() }, 'Git::Wrapper::Exception', '... throws an error if the config dir exists and is a Git repository but no remote repository is defined' );
    $log->contains_ok( qr{Updating config '[.]config'}, '... logs the updating message' );
    $log->empty_ok('... no more logs');

    #
    note('~/.files/.config exists and is a Git repository with a valid remote');
    my ($repositories) = tempdir() =~ m{ (.*) }xsm;
    my $remote_config = File::Spec->catfile( $repositories, 'config.git' );
    make_path($remote_config);

    my $git_remote = Git::Wrapper->new($remote_config);
    $git_remote->init( '-q', '--bare' );

    $git->config( 'user.email', 'test@example.net' );
    $git->config( 'user.name',  'Test User' );
    open my $fh, '>', File::Spec->catfile( $config_path, 'test.txt' );
    close $fh;
    $git->add('test.txt');
    $git->commit( '-q', '-m', 'test' );
    $git->remote( 'add', 'origin', "$repositories/config.git" );
    $git->push( '-q', '--set-upstream', 'origin', 'master' );
    $log->empty_ok('... log is empty');

    like( exception { $obj->run_update() }, qr{Missing config file '$home/[.]files/[.]config/modules[.]ini'}, '... throws an exception if there is no modules.ini file' );
    $log->contains_ok( qr{Updating config '[.]config'}, '... updating message' );
    $log->empty_ok('... no more logs');

    #
    note('with a modules.ini file');
    open $fh, '>', File::Spec->catfile( $config_path, 'modules.ini' );
    close $fh;
    $git->add( File::Spec->catfile( $config_path, 'modules.ini' ) );
    $git->commit( '-q', '-m', 'test' );

    is( $obj->run_update(), undef, 'run_update() returns undef' );
    $log->contains_ok( qr{Updating config '[.]config'},            '... updating message' );
    $log->contains_ok( qr{No modules configured in 'modules.ini'}, q{... logs the warning that no modules are configured in 'modules.ini'} );
    $log->empty_ok('... no more logs');

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
    open $fh, '>', File::Spec->catfile( "${test1_repo}.workspace", 'test.txt' );
    close $fh;
    $git_remote->config( 'user.email', 'test@example.net' );
    $git_remote->config( 'user.name',  'Test User' );
    $git_remote->add('test.txt');
    $git_remote->commit( '-q', '-m', 'test' );
    $git_remote->remote( 'add', 'origin', $test1_repo );
    $git_remote->push( '-q', '--set-upstream', 'origin', 'master' );
    $log->empty_ok('... log is empty');

    open $fh, '>', File::Spec->catfile( $config_path, 'modules.ini' );
    _print( $fh, "[test1]\n" );
    _print( $fh, "pull=$test1_repo\n" );
    close $fh;

    $git->commit( '-q', '-a', '-m', 'test' );

    ok( !-e File::Spec->catfile( $home, '.files', 'test1' ), 'repo test1 does not exist' );

    note('clone');
    is( $obj->run_update(), undef, 'run_update() returns undef' );
    $log->contains_ok( qr{Updating config '[.]config'},                                '... updating message' );
    $log->contains_ok( qr{Cloning repository '$test1_repo' into '$home/.files/test1'}, '... cloning message' );
    $log->contains_ok( qr{Dotfiles updated successfully},                              '... updated successfully message' );
    $log->contains_ok( qr{Planning 'stow' actions},                                    '... planning stow message' );
    $log->contains_ok( qr{Stowing modules test1},                                      '... stowing test1 message' );

    $log->empty_ok('... no more logs');

    ok( -e File::Spec->catfile( $home, '.files', 'test1' ), 'repo test1 does now exist' );

    note('update');
    is( $obj->run_update(), undef, 'run_update() returns undef' );
    $log->contains_ok( qr{Updating config '[.]config'},                  '... updating message' );
    $log->contains_ok( qr{Verifying 'remotes' config of module 'test1'}, '... verifying remotes message' );
    $log->contains_ok( qr{Updating module 'test1'},                      '... other updating message' );
    $log->contains_ok( qr{Dotfiles updated successfully},                '... updated successfully message' );
    $log->contains_ok( qr{Planning 'stow' actions},                      '... planning stow message' );
    $log->contains_ok( qr{Stowing modules test1},                        '... stowing test1 message' );

    $log->empty_ok('... no more logs');

    ok( -e File::Spec->catfile( $home, '.files', 'test1' ), 'repo test1 exists' );

    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
