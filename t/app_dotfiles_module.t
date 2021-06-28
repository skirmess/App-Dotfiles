#!perl

use 5.006;
use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;

use Test::More 0.88;
use Test::Fatal;
use Test::TempDir::Tiny;

use Git::Wrapper;

use Path::Tiny;

use App::Dotfiles::Runtime;
use App::Dotfiles::Module;
use App::Dotfiles::Module::Config;

main();

sub main {
    for my $class (
        'App::Dotfiles::Module',
        'App::Dotfiles::Module::Config',
      )
    {
        note("### class = $class");

        my $home = tempdir();

        my $obj;
        my $name    = 'test';
        my $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

        if ( $class eq 'App::Dotfiles::Module' ) {
            $obj = new_ok( $class, [ runtime => $runtime, name => $name ] );
        }
        elsif ( $class eq 'App::Dotfiles::Module::Config' ) {
            $name = '.config';
            $obj  = new_ok( $class, [ runtime => $runtime ] );
        }
        else {
            BAIL_OUT('INTERNAL ERROR');
        }

        my $test_ws       = File::Spec->catfile( $home, '.files', $name );
        my $test_pull_url = 'http://www.example.net/test.git';

        # does_repository_exist
        is( $obj->does_repository_exist(), undef, q{does_repository_exist() returns 'undef' for a non-existing module} );
        make_path( File::Spec->catfile( $test_ws, '.git' ) );
        like( exception { $obj->does_repository_exist(); }, "/ \QDirectory '$test_ws' exists but is not a valid Git directory\E /xsm", '... and throws an error for an existing, but invalid .git directory' );
        _rmdir( File::Spec->catfile( $test_ws, '.git' ) );

        my $git = Git::Wrapper->new($test_ws);
        $git->init($test_ws);

        is( $obj->does_repository_exist(), 1, q{... and returns '1' for an existing, valid .git directory} );

        # verify_remote
        like( exception { $obj->verify_remote() }, "/ \Q'pull_url' not defined\E /xsm", q{verify_remote() throws an error if 'pull_url' is not defined in the obj} );

        $obj = new_ok( $class, [ %{$obj}, pull_url => $test_pull_url ] );

        like( exception { $obj->verify_remote(); }, "/ \QPull url of remote 'origin' of module '$name' is not configured but should be '$test_pull_url'\E /xsm", '... throws an error if the workspace has no pull origin defined' );

        # defined remote pull url
        $git->remote( 'add', 'origin', 'http://www.example.net/test.git' );

        is( $obj->verify_remote(), undef, '... returns undef if pull_url is correct' );

        my $test_pull_url_incorrect = 'http://www.example.net/test2.git';
        $obj = new_ok( $class, [ %{$obj}, pull_url => $test_pull_url_incorrect ] );
        like( exception { $obj->verify_remote(); }, "/ \QPull url of remote 'origin' of module '$name' is '$test_pull_url' but should be '$test_pull_url_incorrect'\E /xsm", q{... throws an error if the 'pull_url' does not match} );

        my $test_push_url_incorrect = 'http://www.example.net/test3.git';
        $obj = new_ok( $class, [ %{$obj}, pull_url => $test_pull_url, push_url => $test_push_url_incorrect ] );
        like( exception { $obj->verify_remote(); }, "/ \QPush url of remote 'origin' of module '$name' is '$test_pull_url' but should be '$test_push_url_incorrect'\E /xsm", q{... throws an error if the 'push_url' does not match} );

        if ( $class ne 'App::Dotfiles::Module::Config' ) {
            $obj = new_ok( $class, [ runtime => $runtime, name => 'does not exist', pull_url => $test_pull_url ] );
            like( exception { $obj->verify_remote() }, "/ \QModule 'does not exist' does not exist\E /xsm", '... throws an error if the modules directory does not exist' );
        }

        #
        my $repositories = tempdir();
        my $workspaces   = tempdir();

        # Create remote (bare) repository
        my $test_repo = File::Spec->catfile( $repositories, 'test.git' );
        _mkdir($test_repo);
        $git = Git::Wrapper->new($test_repo);
        $git->init( '-q', '--bare' );

        # Create repository
        # (We can't test our Git functionality if the remote repository has no commit)
        $test_ws = File::Spec->catfile( $workspaces, 'test' );
        _mkdir($test_ws);
        $git = Git::Wrapper->new($test_ws);
        $git->init('-q');
        $git->config( 'user.email', 'test@example.net' );
        $git->config( 'user.name',  'Test User' );
        _touch( File::Spec->catfile( $test_ws, 'test.txt' ) );
        $git->add('test.txt');
        $git->commit( '-q', '-m', 'test' );
        $git->remote( 'add', 'origin', "$repositories/test.git" );
        $git->push( '-q', '--set-upstream', 'origin', 'master' );

        # clone_repository
        $home    = tempdir();
        $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

        $obj = new_ok( $class, [ name => $name, runtime => $runtime ] );
        like( exception { $obj->clone_repository(); }, "/ \QCannot clone repository without a 'pull_url'\E /xsm", q{clone_repository() throws an error if no 'pull_url' is defined} );

        $obj = new_ok( $class, [ %{$obj}, pull_url => File::Spec->catfile( $repositories, 'test.git' ) ] );

        my $r_path = File::Spec->catfile( $home, '.files', $name );
        make_path $r_path;

        my $upstream_repo = "$repositories/test.git";

        like( exception { $obj->clone_repository(); }, "/ \QDirectory '$r_path' already exists\E /xsm", q{clone_repository() with 'pull_url' throws an error if the target directory exists already} );
        _rmdir($r_path);

        ok( !-d File::Spec->catfile( $home, '.files', $name ), q{repository 'name' does not exist before cloning it} );

        is( $obj->clone_repository(), undef, '... returns undef on success' );

        is( $obj->verify_remote(), undef, '... configured the remotes correctly' );

        ok( -d File::Spec->catfile( $home, '.files', $name ), q{repository 'name' exists after cloning it} );

        #
        $home    = tempdir();
        $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );
        $r_path  = File::Spec->catfile( $home, '.files', $name );

        $obj = new_ok( $class, [ name => $name, runtime => $runtime, pull_url => $upstream_repo, push_url => 'http://example.net/test.git' ] );
        is( $obj->clone_repository(), undef, 'clone_repository() with pull_url and push_url' );
        is( $obj->verify_remote(),    undef, '... and configured the remotes correctly' );

        # update_repository
        _touch( File::Spec->catfile( $home, '.files', $name, 'test2.txt' ) );

        my $exception = exception { $obj->update_repository() };
        isa_ok( $exception, 'App::Dotfiles::Error::E_REPOSITORY_IS_DIRTY', 'update_repository() throws an error if repository is dirty' );

        _unlink( File::Spec->catfile( $home, '.files', $name, 'test2.txt' ) );

        # add another file to upstream
        _touch( File::Spec->catfile( $test_ws, 'test3.txt' ) );
        $git->add('test3.txt');
        $git->commit( '-q', '-m', 'test' );
        $git->push('-q');

        if ( $class ne 'App::Dotfiles::Module::Config' ) {
            ok( -e File::Spec->catfile( $home,  '.files', 'test', 'test.txt' ),  q{'test.txt' exists} );
            ok( !-e File::Spec->catfile( $home, '.files', 'test', 'test3.txt' ), q{'test3.txt' does not exist} );
        }

        is( $obj->update_repository(), undef, '... returns undef on success' );

        if ( $class ne 'App::Dotfiles::Module::Config' ) {
            ok( -e File::Spec->catfile( $home, '.files', 'test', 'test.txt' ),  q{'test.txt' exists} );
            ok( -e File::Spec->catfile( $home, '.files', 'test', 'test3.txt' ), q{'test3.txt' exists after update} );
        }

        # get_repository_status
        is( scalar $obj->get_repository_status(), 0, 'get_repository_status() returns an empty list for clean module' );

        my $f1 = File::Spec->catfile( $home, '.files', $name, 'test2.txt' );
        _touch($f1);

        my $status_expected_ref = [ [ q{??}, $f1 ], ];
        my @status              = $obj->get_repository_status();
        is_deeply( \@status, $status_expected_ref, 'returns correct modifications for dirty module' );

        my $f2 = File::Spec->catfile( $home, '.files', $name, 'test4.txt' );
        _touch($f2);

        push @{$status_expected_ref}, [ q{??}, $f2 ];
        @status = $obj->get_repository_status();
        is_deeply( \@status, $status_expected_ref, 'returns correct modifications for dirty module' );
    }

    #
    done_testing();

    exit 0;
}

sub _mkdir {
    my ($dir) = @_;

    my $rc = mkdir $dir;
    BAIL_OUT("mkdir $dir: $!") if !$rc;
    return $rc;
}

sub _rmdir {
    my ($dir) = @_;

    my $rc = rmdir $dir;
    BAIL_OUT("rmdir $dir: $!") if !$rc;
    return $rc;
}

sub _touch {
    my ( $file, @content ) = @_;

    path($file)->spew(@content) or BAIL_OUT("Cannot write file '$file': $!");

    return;
}

sub _unlink {
    my (@files) = @_;

    my $rc = unlink @files;
    BAIL_OUT("unlink @files: $!") if !$rc;
    return $rc;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
