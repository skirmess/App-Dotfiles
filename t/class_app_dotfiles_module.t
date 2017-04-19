#!perl -T

use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::More;
use Test::TempDir::Tiny;

use Log::Any::Test;
use Log::Any qw($log);

use File::Spec;

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

        my $home           = tempdir();
        my $home2          = tempdir();
        my $home3          = tempdir();
        my $dotfiles_path3 = tempdir();

        my $runtime  = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );
        my $runtime2 = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home2 ] );
        my $runtime3 = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home3, dotfiles_path => $dotfiles_path3, modules_config_file => 'CONFIG_FILE' ] );

        my $name = 'abc';
        my $obj;

        my $name2 = 'NAME_2';
        my $obj2  = new_ok(
            $class,
            [
                runtime                       => $runtime2,
                name                          => $name2,
                _verify_remotes_before_update => 'SHOULD_BE_IGNORED',
                module_path                   => 'SHOULD_BE_IGNORED',
                pull_url                      => 'http://example.net/TEST_PULL.git',
                push_url                      => 'http://example.net/TEST_PUSH.git',
                git                           => 'SHOULD_BE_IGNORED',
                modules_config_file_path      => 'SHOULD_BE_IGNORED',
            ]
        );

        my $name3 = 'NAME_3';
        my $obj3  = new_ok(
            $class,
            [
                runtime                       => $runtime3,
                name                          => $name3,
                _verify_remotes_before_update => 'SHOULD_BE_IGNORED',
                module_path                   => 'SHOULD_BE_IGNORED',
                pull_url                      => 'http://example.net/TEST_PULL.git',
                push_url                      => 'http://example.net/TEST_PUSH.git',
                git                           => 'SHOULD_BE_IGNORED',
                modules_config_file_path      => 'SHOULD_BE_IGNORED',
            ]
        );

        #
        if ( $class eq 'App::Dotfiles::Module' ) {
            like( exception { $class->new( name    => $name ) },    qr{Missing required arguments: runtime}, q{'runtime' is required with 'new()'} );
            like( exception { $class->new( runtime => $runtime ) }, qr{Missing required arguments: name},    q{'name' is required with 'new()'} );

            $obj = new_ok( $class, [ runtime => $runtime, name => $name ] );

            is( $obj->_verify_remotes_before_update, 1, q{attribute '_verify_remotes_before_update'} );
            like( exception { $obj->_verify_remotes_before_update('abc') }, qr{is a read-only accessor}, '... is a read-only accessor' );

            is( $obj2->_verify_remotes_before_update, 1, q{attribute '_verify_remotes_before_update'} );
            is( $obj3->_verify_remotes_before_update, 1, q{attribute '_verify_remotes_before_update'} );
        }
        elsif ( $class eq 'App::Dotfiles::Module::Config' ) {
            like( exception { $class->new() }, qr{Missing required arguments: runtime}, q{'runtime' is required with 'new()'} );

            $name3 = $name2 = $name = '.config';

            $obj = new_ok( $class, [ runtime => $runtime, name => 'abc' ] );
            is( $obj->name, $name, q{'name' is ignored by new()} );
            like( exception { $obj->name('abc') }, qr{is a read-only accessor}, '... is a read-only accessor' );

            is( $obj2->name, $name, q{'name' is ignored by new()} );
            is( $obj3->name, $name, q{'name' is ignored by new()} );

            $obj = new_ok( $class, [ runtime => $runtime ] );
            is( $obj->_verify_remotes_before_update, 0, q{attribute '_verify_remotes_before_update'} );
            like( exception { $obj->_verify_remotes_before_update('abc') }, qr{is a read-only accessor}, '... is a read-only accessor' );

            is( $obj2->_verify_remotes_before_update, 0, q{attribute '_verify_remotes_before_update'} );
            is( $obj3->_verify_remotes_before_update, 0, q{attribute '_verify_remotes_before_update'} );

            is( $obj->modules_config_file_path,  File::Spec->catfile( $home,  '.files', '.config', 'modules.ini' ), q{attribute 'modules_config_file_path'} );
            is( $obj2->modules_config_file_path, File::Spec->catfile( $home2, '.files', '.config', 'modules.ini' ), q{'modules_config_file_path' is ignored by new()} );
            is( $obj3->modules_config_file_path, File::Spec->catfile( $dotfiles_path3, '.config', 'CONFIG_FILE' ), q{'modules_config_file_path' is ignored by new()} );
        }
        else {
            BAIL_OUT('INTERNAL ERROR');
        }

        ok( $obj->does('App::Dotfiles::Role::Runtime'),    "$class does 'App::Dotfiles::Role::Runtime'" );
        ok( $obj->does('App::Dotfiles::Role::Repository'), "$class does 'App::Dotfiles::Role::Repository'" );

        isa_ok( $obj->runtime, 'App::Dotfiles::Runtime' );
        like( exception { $obj->runtime('abc') }, qr{is a read-only accessor}, '... is a read-only accessor' );
        isa_ok( $obj2->runtime, 'App::Dotfiles::Runtime' );
        isa_ok( $obj3->runtime, 'App::Dotfiles::Runtime' );

        is( $obj->runtime->home_path, $home, '->runtime->home_path is initialized correctly' );
        like( exception { $obj->runtime->home_path('abc') }, qr{is a read-only accessor}, '... is a read-only accessor' );
        is( $obj2->runtime->home_path, $home2, '->runtime->home_path is initialized correctly' );
        is( $obj3->runtime->home_path, $home3, '->runtime->home_path is initialized correctly' );

        is( $obj->runtime->dotfiles_path, File::Spec->catfile( $home, '.files' ), '->runtime->dotfiles_path is initialized correctly' );
        like( exception { $obj->runtime->dotfiles_path('abc') }, qr{is a read-only accessor}, '... is a read-only accessor' );
        is( $obj2->runtime->dotfiles_path, File::Spec->catfile( $home2, '.files' ), '->runtime->dotfiles_path is initialized correctly' );
        is( $obj3->runtime->dotfiles_path, $dotfiles_path3, '->runtime->dotfiles_path is initialized correctly' );

        is( $obj->name, $name, q{attribute 'name'} );
        like( exception { $obj->name('abc') }, qr{is a read-only accessor}, '... is a read-only accessor' );
        is( $obj2->name, $name2, q{attribute 'name'} );
        is( $obj3->name, $name3, q{attribute 'name'} );

        is( $obj->module_path, File::Spec->catfile( $home, '.files', $name ), q{attribute 'module_path'} );
        like( exception { $obj->module_path('abc') }, qr{is a read-only accessor}, '... is a read-only accessor' );
        is( $obj2->module_path, File::Spec->catfile( $home2, '.files', $name2 ), q{attribute 'module_path'} );
        is( $obj3->module_path, File::Spec->catfile( $dotfiles_path3, $name3 ), q{attribute 'module_path'} );

        is( $obj->pull_url, undef, q{attribute 'pull_url'} );
        like( exception { $obj->pull_url('abc') }, qr{is a read-only accessor}, '... is a read-only accessor' );
        is( $obj2->pull_url, 'http://example.net/TEST_PULL.git', q{attribute 'pull_url'} );
        is( $obj3->pull_url, 'http://example.net/TEST_PULL.git', q{attribute 'pull_url'} );

        is( $obj->push_url, undef, q{attribute 'push_url'} );
        like( exception { $obj->push_url('abc') }, qr{is a read-only accessor}, '... is a read-only accessor' );
        is( $obj2->push_url, 'http://example.net/TEST_PUSH.git', q{attribute 'push_url'} );
        is( $obj3->push_url, 'http://example.net/TEST_PUSH.git', q{attribute 'push_url'} );

        # git
        isa_ok( $obj->git, 'Git::Wrapper', q{attribute 'git'} );
        like( exception { $obj->git('abc') }, qr{is a read-only accessor}, '... is a read-only accessor' );
        isa_ok( $obj2->git, 'Git::Wrapper', q{attribute 'git'} );
        isa_ok( $obj3->git, 'Git::Wrapper', q{attribute 'git'} );
    }

    #
    $log->empty_ok('nothing was logged');

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
