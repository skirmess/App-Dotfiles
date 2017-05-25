#!perl
use strict;
use warnings;
use autodie;

use Test::Fatal;

use Test::More;
use Test::TempDir::Tiny;

use File::Path qw(make_path);
use File::Spec;

use Git::Wrapper;

use Capture::Tiny qw(capture);

use App::Dotfiles::CLI;

my $env_home;

BEGIN {
    $ENV{HOME} = $env_home = tempdir();
}

use English qw(-no_match_vars);

## no critic (RegularExpressions::RequireDotMatchAnything)
## no critic (RegularExpressions::RequireExtendedFormatting)
## no critic (RegularExpressions::RequireLineBoundaryMatching)
## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
## no critic (NamingConventions::Capitalization)

main();

sub _note_ARGV {
    local $LIST_SEPARATOR = q{', '};
    note("\@ARGV = ('@ARGV')");
    return;
}

sub main {
    my $home = tempdir();

    ok( $home ne $env_home, '$home ne $env_home' );

    note('_get_main_options_and_command');

    #
    {
        my $obj = new_ok('App::Dotfiles::CLI');
        local @ARGV = qw(--no-such-option);
        _note_ARGV();

        my $exception = exception { $obj->_get_main_options_and_command() };
        isa_ok( $exception, 'App::Dotfiles::Error::E_USAGE', '... throws an E_USAGE error with invalid options' );
        like( $exception, qr{usage error in global option section}, '... with the correct message' );
        is_deeply( \@ARGV, [], '... @ARGV is empty' );
    }

    #
    {
        my $obj = new_ok('App::Dotfiles::CLI');
        local @ARGV = qw(status);
        _note_ARGV();

        my ( $opt_ref, $cmd ) = $obj->_get_main_options_and_command();
        is( $cmd, 'status', q{... returns command 'status'} );
        is_deeply( $opt_ref, {}, '... and no options' );
        is_deeply( \@ARGV, [], '... @argv is empty' );
    }

    #
    {
        my $obj = new_ok('App::Dotfiles::CLI');
        local @ARGV = ( '-h', $home, 'status' );
        _note_ARGV();

        my ( $opt_ref, $cmd ) = $obj->_get_main_options_and_command();
        is( $cmd, 'status', q{... returns command 'status'} );
        is_deeply( $opt_ref, { h => $home }, '... and the correct options' );
        is_deeply( \@ARGV, [], '... @argv is empty' );
    }

    #
    {
        my $obj = new_ok('App::Dotfiles::CLI');
        local @ARGV = ( '-h', $home, 'status', '-x' );
        _note_ARGV();

        my ( $opt_ref, $cmd ) = $obj->_get_main_options_and_command();
        is( $cmd, 'status', q{... returns command 'status'} );
        is_deeply( $opt_ref, { h => $home }, '... and the correct options' );
        is_deeply( \@ARGV, [qw(-x)], '... @argv is reduced' );
    }

    #
    {
        my $obj = new_ok('App::Dotfiles::CLI');
        local @ARGV = ( '-h', $home, '-x', 'status' );
        _note_ARGV();

        my $exception = exception { $obj->_get_main_options_and_command() };
        isa_ok( $exception, 'App::Dotfiles::Error::E_USAGE', '... throws an E_USAGE error with invalid options' );
        like( $exception, qr{usage error in global option section}, '... with the correct message' );
    }

    #
    {
        my $obj = new_ok('App::Dotfiles::CLI');
        local @ARGV = ( '-h', $home );
        _note_ARGV();

        my $exception = exception { $obj->_get_main_options_and_command() };
        isa_ok( $exception, 'App::Dotfiles::Error::E_USAGE', '... throws an E_USAGE error without a command' );
        like( $exception, qr{no command given}, '... with the correct message' );
    }

    #
    {
        my $obj = new_ok('App::Dotfiles::CLI');
        local @ARGV = ();
        _note_ARGV();

        my $exception = exception { $obj->_get_main_options_and_command() };
        isa_ok( $exception, 'App::Dotfiles::Error::E_USAGE', '... throws an E_USAGE error without a command' );
        like( $exception, qr{no command given}, '... with the correct message' );
    }

    note('_cmd_version');

    #
    {
        my $obj = new_ok('App::Dotfiles::CLI');
        local @ARGV = ();
        _note_ARGV();

        my ( $stdout, $stderr, @result ) = capture { $obj->_cmd_version() };
        is( $result[0], undef, '... returns undef' );
        like( $stdout, qr{dotf version \d[.]\d+}, '... prints the version to stdout' );
        is( $stderr, q{}, '... and nothing to stderr' );

        is_deeply( \@ARGV, [], '... @ARGV is empty' );
    }

    {
        my $obj = new_ok('App::Dotfiles::CLI');
        local @ARGV = qw(--no-such-option);
        _note_ARGV();

        my $exception = exception { $obj->_cmd_version() };
        isa_ok( $exception, 'App::Dotfiles::Error::E_USAGE', '... throws an E_USAGE error with invalid options' );
        like( $exception, qr{usage error in command option section}, '... with the correct message' );
        is_deeply( \@ARGV, [qw(--no-such-option)], '... @ARGV is empty' );
    }

    note('_cmd_help');

    #
    {
        my $obj = new_ok('App::Dotfiles::CLI');
        local @ARGV = qw(--no-such-option);
        _note_ARGV();

        my $exception = exception { $obj->_cmd_help() };
        isa_ok( $exception, 'App::Dotfiles::Error::E_USAGE', '... throws an E_USAGE error with invalid options' );
        like( $exception, qr{usage error in command option section}, '... with the correct message' );
        is_deeply( \@ARGV, [qw(--no-such-option)], '... @ARGV is empty' );
    }

    note('_cmd_init');

    #
    {
        my $obj = new_ok('App::Dotfiles::CLI');
        local @ARGV = ();
        _note_ARGV();

        my $exception = exception { $obj->_cmd_init() };
        isa_ok( $exception, 'App::Dotfiles::Error::E_USAGE', '... throws an E_USAGE error with invalid options' );
        like( $exception, qr{usage error in command option section}, '... with the correct message' );
        is_deeply( \@ARGV, [], '... @ARGV is empty' );
    }

    {
        my $obj = new_ok('App::Dotfiles::CLI');
        local @ARGV = qw(http://www.example.net/test1.git http://www.example.net/test2.git);
        _note_ARGV();

        my $exception = exception { $obj->_cmd_init() };
        isa_ok( $exception, 'App::Dotfiles::Error::E_USAGE', '... throws an E_USAGE error with invalid options' );
        like( $exception, qr{usage error in command option section}, '... with the correct message' );
        is_deeply( \@ARGV, [qw(http://www.example.net/test1.git http://www.example.net/test2.git)], '... @ARGV is empty' );
    }

    note('_cmd_status');

    #
    {
        my $obj = new_ok('App::Dotfiles::CLI');
        local @ARGV = qw(--no-such-option);
        _note_ARGV();

        my $exception = exception { $obj->_cmd_status() };
        isa_ok( $exception, 'App::Dotfiles::Error::E_USAGE', '... throws an E_USAGE error with invalid options' );
        like( $exception, qr{usage error in command option section}, '... with the correct message' );
        is_deeply( \@ARGV, [qw(--no-such-option)], '... @ARGV is empty' );
    }

    note('_cmd_update');

    #
    {
        my $obj = new_ok('App::Dotfiles::CLI');
        local @ARGV = qw(--no-such-option);
        _note_ARGV();

        my $exception = exception { $obj->_cmd_update() };
        isa_ok( $exception, 'App::Dotfiles::Error::E_USAGE', '... throws an E_USAGE error with invalid options' );
        like( $exception, qr{usage error in command option section}, '... with the correct message' );
        is_deeply( \@ARGV, [qw(--no-such-option)], '... @ARGV is empty' );
    }

    note('main');

    #
    {
        my $obj = new_ok('App::Dotfiles::CLI');
        local @ARGV = qw(no-such-command);
        _note_ARGV();

        my $exception = exception { $obj->main() };
        isa_ok( $exception, 'App::Dotfiles::Error::E_USAGE', '... throws an E_USAGE error with invalid command' );
        like( $exception, qr{unrecognized command 'no-such-command'}, '... with the correct message' );
        is_deeply( \@ARGV, [], '... @ARGV is empty' );
    }

    #
    {
        my $obj = new_ok('App::Dotfiles::CLI');
        local @ARGV = qw(version);
        _note_ARGV();

        is( $obj->runtime, undef, q{... attribute 'runtime' is not defined} );

        my ( $stdout, $stderr, @result ) = capture { $obj->main() };
        is( $result[0], undef, '... returns undef' );
        like( $stdout, qr{dotf version \d[.]\d+}, '... prints the version to stdout' );
        is( $stderr, q{}, '... and nothing to stderr' );

        isa_ok( $obj->runtime, 'App::Dotfiles::Runtime' );
        is( $obj->runtime->home_path, $env_home, q{... 'home_path' is configured to $HOME} );
        is_deeply( \@ARGV, [], '... @ARGV is empty' );
    }

    #
    {
        my $obj = new_ok('App::Dotfiles::CLI');
        local @ARGV = ( '-h', $home, 'version' );
        _note_ARGV();

        is( $obj->runtime, undef, q{... attribute 'runtime' is not defined} );

        my ( $stdout, $stderr, @result ) = capture { $obj->main() };
        is( $result[0], undef, '... returns undef' );
        like( $stdout, qr{dotf version \d[.]\d+}, '... prints the version to stdout' );
        is( $stderr, q{}, '... and nothing to stderr' );

        isa_ok( $obj->runtime, 'App::Dotfiles::Runtime' );
        is( $obj->runtime->home_path, $home, q{... 'home_path' is the one from the command line} );
        is_deeply( \@ARGV, [], '... @ARGV is empty' );
    }

    #
    {
        my $obj = new_ok('App::Dotfiles::CLI');
        local @ARGV = qw(help);
        _note_ARGV();

        is( $obj->runtime, undef, q{... attribute 'runtime' is not defined} );

        my ( $stdout, $stderr, @result ) = capture { $obj->main() };
        is( $result[0], undef, '... returns undef' );
        is( $stdout,    q{},   '... prints nothing to stdout' );
        is( $stderr,    q{},   '... and nothing to stderr' );

        isa_ok( $obj->runtime, 'App::Dotfiles::Runtime' );
        is( $obj->runtime->home_path, $env_home, q{... 'home_path' is configured to $HOME} );
        is_deeply( \@ARGV, [], '... @ARGV is empty' );
    }

    #
    {
        my $obj = new_ok('App::Dotfiles::CLI');
        local @ARGV = qw(version --no-such-option);
        _note_ARGV();

        my $exception = exception { $obj->main() };
        isa_ok( $exception, 'App::Dotfiles::Error::E_USAGE', '... throws an E_USAGE error with invalid options' );
        like( $exception, qr{usage error in command option section}, '... with the correct message' );
        is_deeply( \@ARGV, [qw(--no-such-option)], '... @ARGV is empty' );
    }

    {
        my $obj = new_ok('App::Dotfiles::CLI');
        local @ARGV = qw(init http://www.example.net/test3.git);
        _note_ARGV();

        my ( $stdout, $stderr, @result ) = capture {
            exception { $obj->main() }
        };
        chomp $stdout;
        isa_ok( $result[0], 'Git::Wrapper::Exception', '... throws an Git::Wrapper::Exception error with invalid repository' );
        is( $stdout, q{Initializing config '.config'}, '... prints initializing message' );
        is( $stderr, q{}, '... and nothing to stderr' );

        is_deeply( \@ARGV, [], '... @ARGV is empty' );
    }

    my $config_repo_path = tempdir();
    {
        my $config_repo = Git::Wrapper->new($config_repo_path);
        $config_repo->init('-q');

        open my $fh, '>', File::Spec->catfile( $config_repo_path, 'modules.ini' );
        close $fh;

        $config_repo->add('modules.ini');

        $config_repo->config( 'user.email', 'test@example.net' );
        $config_repo->config( 'user.name',  'Test User' );

        $config_repo->commit( '-q', '-m', 'commit' );
    }

    {
        my $obj = new_ok('App::Dotfiles::CLI');
        local @ARGV = ( 'init', $config_repo_path );
        _note_ARGV();

        my ( $stdout, $stderr, @result ) = capture { $obj->main() };
        my @stdout = split /\n/, $stdout;
        chomp @stdout;

        is( $result[0], undef,                                     '... returns undef' );
        is( $stdout[0], q{Initializing config '.config'},          '... prints initializing message' );
        is( $stdout[1], q{No modules configured in 'modules.ini'}, '... prints no modules configured message' );
        is( @stdout,    2,                                         '... no more output on stderr' );
        is( $stderr,    q{},                                       '... and nothing to stderr' );

        is_deeply( \@ARGV, [], '... @ARGV is empty' );
    }

    {
        my $obj = new_ok('App::Dotfiles::CLI');
        local @ARGV = qw(status);
        _note_ARGV();

        my ( $stdout, $stderr, @result ) = capture { $obj->main() };
        is( $result[0], undef, '... returns undef' );
        is( $stdout,    q{},   '... prints nothing to stdout' );
        is( $stderr,    q{},   '... and nothing to stderr' );

        is_deeply( \@ARGV, [], '... @ARGV is empty' );
    }

    {
        my $obj = new_ok('App::Dotfiles::CLI');
        local @ARGV = qw(update);
        _note_ARGV();

        my ( $stdout, $stderr, @result ) = capture { $obj->main() };
        my @stdout = split /\n/, $stdout;
        chomp @stdout;

        is( $result[0], undef,                                     '... returns undef' );
        is( $stdout[0], q{Updating config '.config'},              '... prints updating message' );
        is( $stdout[1], q{No modules configured in 'modules.ini'}, '... prints no modules configured message' );
        is( @stdout,    2,                                         '... no more output on stderr' );
        is( $stderr,    q{},                                       '... and nothing to stderr' );

        is_deeply( \@ARGV, [], '... @ARGV is empty' );
    }

    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
