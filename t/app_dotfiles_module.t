#!perl
use strict;
use warnings;
use autodie;

use File::Path qw(make_path);
use File::Spec;

use Test::More;
use Test::Fatal;
use Test::TempDir::Tiny;

use Log::Any::Test;
use Log::Any qw($log);

use Git::Wrapper;

use App::Dotfiles::Runtime;
use App::Dotfiles::Module;
use App::Dotfiles::Module::Config;

## no critic (RegularExpressions::RequireDotMatchAnything)
## no critic (RegularExpressions::RequireExtendedFormatting)
## no critic (RegularExpressions::RequireLineBoundaryMatching)

main();

sub main {
    for my $class (
        'App::Dotfiles::Module',
        'App::Dotfiles::Module::Config',
      )
    {
        note("### class = $class");

        # untaint
        my ($home) = tempdir() =~ m{ (.*) }xms;
        local ( $ENV{PATH} ) = $ENV{PATH} =~ m{ (.*) }xms;

        my $obj;
        my $name = 'test';
        my $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

        if ( $class eq 'App::Dotfiles::Module' ) {
            $obj = new_ok( $class, [ runtime => $runtime, name => $name ] );
        }
        elsif ( $class eq 'App::Dotfiles::Module::Config' ) {
            $name = '.config';
            $obj = new_ok( $class, [ runtime => $runtime ] );
        }
        else {
            BAIL_OUT('INTERNAL ERROR');
        }

        my $test_ws       = File::Spec->catfile( $home, '.files', $name );
        my $test_ws_qm    = quotemeta $test_ws;
        my $test_pull_url = 'http://www.example.net/test.git';

        # does_repository_exist
        is( $obj->does_repository_exist(), undef, q{does_repository_exist() returns 'undef' for a non-existing module} );
        make_path( File::Spec->catfile( $test_ws, '.git' ) );
        like( exception { $obj->does_repository_exist(); }, qr{Directory '$test_ws_qm' exists but is not a valid Git directory}, '... and throws an error for an existing, but invalid .git directory' );
        rmdir( File::Spec->catfile( $test_ws, '.git' ) );

        my $git = Git::Wrapper->new($test_ws);
        $git->init($test_ws);

        is( $obj->does_repository_exist(), 1, q{... and returns '1' for an existing, valid .git directory} );

        # verify_remote
        like( exception { $obj->verify_remote() }, qr{'pull_url' not defined}, q{verify_remote() throws an error if 'pull_url' is not defined in the obj} );

        $obj = new_ok( $class, [ %{$obj}, pull_url => $test_pull_url ] );

        like( exception { $obj->verify_remote(); }, qr{Pull url of remote 'origin' of module '$name' is not configured but should be '$test_pull_url'}, '... throws an error if the workspace has no pull origin defined' );

        # defined remote pull url
        $git->remote( 'add', 'origin', 'http://www.example.net/test.git' );

        is( $obj->verify_remote(), undef, '... returns undef if pull_url is correct' );

        my $test_pull_url_incorrect = 'http://www.example.net/test2.git';
        $obj = new_ok( $class, [ %{$obj}, pull_url => $test_pull_url_incorrect ] );
        like( exception { $obj->verify_remote(); }, qr{Pull url of remote 'origin' of module '$name' is '$test_pull_url' but should be '$test_pull_url_incorrect'}, q{... throws an error if the 'pull_url' does not match} );

        my $test_push_url_incorrect = 'http://www.example.net/test3.git';
        $obj = new_ok( $class, [ %{$obj}, pull_url => $test_pull_url, push_url => $test_push_url_incorrect ] );
        like( exception { $obj->verify_remote(); }, qr{Push url of remote 'origin' of module '$name' is '$test_pull_url' but should be '$test_push_url_incorrect'}, q{... throws an error if the 'push_url' does not match} );

        if ( $class ne 'App::Dotfiles::Module::Config' ) {
            $obj = new_ok( $class, [ runtime => $runtime, name => 'does not exist', pull_url => $test_pull_url ] );
            like( exception { $obj->verify_remote() }, qr{Module 'does not exist' does not exist}, '... throws an error if the modules directory does not exist' );
        }

        #
        my ($repositories) = tempdir() =~ m{ (.*) }xms;
        my ($workspaces)   = tempdir() =~ m{ (.*) }xsm;

        # Create remote (bare) repository
        my $test_repo = File::Spec->catfile( $repositories, 'test.git' );
        mkdir "$test_repo";
        $git = Git::Wrapper->new($test_repo);
        $git->init( '-q', '--bare' );

        # Create repository
        # (We can't test our Git functionality if the remote repository has no commit)
        $test_ws = File::Spec->catfile( $workspaces, 'test' );
        mkdir "$test_ws";
        $git = Git::Wrapper->new($test_ws);
        $git->init('-q');
        $git->config( 'user.email', 'test@example.net' );
        $git->config( 'user.name',  'Test User' );
        open my $fh, '>', File::Spec->catfile( $test_ws, 'test.txt' );
        close $fh;
        $git->add('test.txt');
        $git->commit( '-q', '-m', 'test' );
        $git->remote( 'add', 'origin', "$repositories/test.git" );
        $git->push( '-q', '--set-upstream', 'origin', 'master' );

        # clone_repository
        ($home) = tempdir() =~ m{ (.*) }xms;
        $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

        $obj = new_ok( $class, [ name => $name, runtime => $runtime ] );
        like( exception { $obj->clone_repository(); }, qr{Cannot clone repository without a 'pull_url'}, q{clone_repository() throws an error if no 'pull_url' is defined} );

        $obj = new_ok( $class, [ %{$obj}, pull_url => File::Spec->catfile( $repositories, 'test.git' ) ] );

        my $r_path = File::Spec->catfile( $home, '.files', $name );
        my $r_path_qm = quotemeta $r_path;
        make_path $r_path;

        my $upstream_repo    = "$repositories/test.git";
        my $upstream_repo_qm = quotemeta $upstream_repo;

        like( exception { $obj->clone_repository(); }, qr{Directory '$r_path_qm' already exists}, q{clone_repository() with 'pull_url' throws an error if the target directory exists already} );
        rmdir $r_path;

        ok( !-d File::Spec->catfile( $home, '.files', $name ), q{repository 'name' does not exist before cloning it} );

        is( $obj->clone_repository(), undef, '... returns undef on success' );

        is( $obj->verify_remote(), undef, '... configured the remotes correctly' );

        ok( -d File::Spec->catfile( $home, '.files', $name ), q{repository 'name' exists after cloning it} );

        #
        ($home) = tempdir() =~ m{ (.*) }xms;
        $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );
        $r_path = File::Spec->catfile( $home, '.files', $name );
        $r_path_qm = quotemeta $r_path;

        $obj = new_ok( $class, [ name => $name, runtime => $runtime, pull_url => $upstream_repo, push_url => 'http://example.net/test.git' ] );
        is( $obj->clone_repository(), undef, 'clone_repository() with pull_url and push_url' );
        is( $obj->verify_remote(),    undef, '... and configured the remotes correctly' );

        # update_repository
        open $fh, '>', File::Spec->catfile( $home, '.files', $name, 'test2.txt' );
        close $fh;

        my $exception = exception { $obj->update_repository() };
        isa_ok( $exception, 'App::Dotfiles::Error::E_REPOSITORY_IS_DIRTY', 'update_repository() throws an error if repository is dirty' );

        unlink File::Spec->catfile( $home, '.files', $name, 'test2.txt' );

        # add another file to upstream
        open $fh, '>', File::Spec->catfile( $test_ws, 'test3.txt' );
        close $fh;
        $git->add('test3.txt');
        $git->commit( '-q', '-m', 'test' );
        $git->push('-q');

        if ( $class ne 'App::Dotfiles::Module::Config' ) {
            ok( -e File::Spec->catfile( $home, '.files', 'test', 'test.txt' ), q{'test.txt' exists} );
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
        open $fh, '>', $f1;
        close $fh;

        my $status_expected_ref = [ [ q{??}, $f1 ], ];
        my @status = $obj->get_repository_status();
        is_deeply( \@status, $status_expected_ref, 'returns correct modifications for dirty module' );

        my $f2 = File::Spec->catfile( $home, '.files', $name, 'test4.txt' );
        open $fh, '>', $f2;
        close $fh;

        push @{$status_expected_ref}, [ q{??}, $f2 ];
        @status = $obj->get_repository_status();
        is_deeply( \@status, $status_expected_ref, 'returns correct modifications for dirty module' );
    }

    #
    note(q{#});
    $log->empty_ok('nothing was logged');

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
