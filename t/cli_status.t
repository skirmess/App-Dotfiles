#!perl

use 5.006;
use strict;
use warnings;

use Carp;

use Test::Fatal;
use Test::More;
use Test::TempDir::Tiny;

use File::Path qw(make_path);
use File::Spec;

use Git::Wrapper;
use Path::Tiny;

use Capture::Tiny qw(capture);

use App::Dotfiles::Runtime;
use App::Dotfiles::CLI::Command;

main();

sub main {
    my $home = tempdir();

    my $runtime = new_ok( 'App::Dotfiles::Runtime',      [ home_path => $home ] );
    my $obj     = new_ok( 'App::Dotfiles::CLI::Command', [ runtime   => $runtime ] );

    #
    note('~/.files does not exist');
    {
        my ( $stdout, $stderr, @result ) = capture {
            exception { $obj->run_status() }
        };
        isa_ok( $result[0], 'App::Dotfiles::Error::E_NO_CONFIG_REPOSITORY', 'run_status() throws an exception when the config dir does not exist.' );
        is( $stdout, q{}, '... prints nothing to stdout' );
        is( $stderr, q{}, '... and nothing to stderr' );
    }

    #
    note('~/.files/.config exists but is not a Git repository');
    my $config_path = File::Spec->catfile( $home, '.files', '.config' );
    make_path( File::Spec->catfile( $config_path, '.git' ) );

    my $config_dir_path = File::Spec->catfile( $home, '.files', '.config' );

    {
        my ( $stdout, $stderr, @result ) = capture {
            exception { $obj->run_status() }
        };
        like( $result[0], "/ \QDirectory '$config_dir_path' exists but is not a valid Git directory\E /xsm", '... throws an axception when the config dir exists but is not a Git repository' );
        is( $stdout, q{}, '... prints nothing to stdout' );
        is( $stderr, q{}, '... and nothing to stderr' );
    }

    #
    note('~/.files/.config exists and is a Git repository');
    my $git = Git::Wrapper->new($config_path);
    $git->init();

    my $config_file_path = File::Spec->catfile( $home, '.files', '.config', 'modules.ini' );

    {
        my ( $stdout, $stderr, @result ) = capture {
            exception { $obj->run_status() }
        };
        like( $result[0], "/ \QMissing config file '$config_file_path'\E /xsm", 'run_status() throws an error if the config file is missing' );
        is( $stdout, q{}, '... prints nothing to stdout' );
        is( $stderr, q{}, '... and nothing to stderr' );
    }

    #
    note('add config file');
    my $config_file = File::Spec->catfile( $home, '.files', '.config', 'modules.ini' );
    _touch($config_file);

    {
        my ( $stdout, $stderr, @result ) = capture { $obj->run_status() };
        chomp $stdout;
        is( $result[0], undef,                  'run_status() returns undef with empty config file' );
        is( $stdout,    "?? $config_file_path", '... prints the not-commited config file to stdot' );
        is( $stderr,    q{},                    '... and nothing to stderr' );
    }

    #
    note('one additional module (present, but not in config)');
    make_path( File::Spec->catfile( $home, '.files', 'additional_module_1' ) );

    {
        my ( $stdout, $stderr, @result ) = capture { $obj->run_status() };
        is( $result[0], undef, 'run_status() returns undef' );
        my @stdout = split /\n/xsm, $stdout;
        chomp @stdout;
        is( $stdout[0], "?? $config_file_path",                '... prints config file' );
        is( $stdout[1], " + $home/.files/additional_module_1", '... prints additional module' );
        is( @stdout,    2,                                     '... no more output' );
        is( $stderr,    q{},                                   '... and nothing to stderr' );
    }

    #
    note('add additional module to config file');
    _touch( $config_file, <<'EOF');
[additional_module_1]
pull=http://www.example.net/test.git
EOF

    {
        my ( $stdout, $stderr, @result ) = capture { $obj->run_status() };
        is( $result[0], undef, 'run_status() returns undef' );
        my @stdout = split /\n/xsm, $stdout;
        chomp @stdout;
        is( $stdout[0], "?? $home/.files/.config/modules.ini", '... prints config file' );
        is( $stdout[1], " ~ $home/.files/additional_module_1", '... prints additional module' );
        is( @stdout,    2,                                     '... no more output' );
        is( $stderr,    q{},                                   '... and nothing to stderr' );
    }

    #
    note('mention another module in config file');
    _touch( $config_file, <<'EOF');
[additional_module_2]
pull=http://www.example.net/test.git
EOF

    {
        my ( $stdout, $stderr, @result ) = capture { $obj->run_status() };
        is( $result[0], undef, 'run_status() returns undef' );
        my @stdout = split /\n/xsm, $stdout;
        chomp @stdout;
        is( $stdout[0], "?? $home/.files/.config/modules.ini", '... prints config file' );
        is( $stdout[1], " + $home/.files/additional_module_1", '... prints additional module' );
        is( $stdout[2], " - $home/.files/additional_module_2", '... prints missing module' );
        is( @stdout,    3,                                     '... no more output' );
        is( $stderr,    q{},                                   '... and nothing to stderr' );
    }

    #
    note('one additional module, one git repository');
    my $module2_path = File::Spec->catfile( $home, '.files', 'additional_module_2' );
    make_path($module2_path);
    my $git_module2 = Git::Wrapper->new($module2_path);
    $git_module2->init();

    {
        my ( $stdout, $stderr, @result ) = capture { $obj->run_status() };
        is( $result[0], undef, 'run_status() returns undef' );
        my @stdout = split /\n/xsm, $stdout;
        chomp @stdout;
        is( $stdout[0], "?? $home/.files/.config/modules.ini", '... prints config file' );
        is( $stdout[1], " + $home/.files/additional_module_1", '... prints additional module' );
        is( @stdout,    2,                                     '... no more output' );
        is( $stderr,    q{},                                   '... and nothing to stderr' );
    }

    #
    note('add changes to module2');
    _touch( File::Spec->catfile( $module2_path, 'a.txt' ) );

    {
        my ( $stdout, $stderr, @result ) = capture { $obj->run_status() };
        is( $result[0], undef, 'run_status() returns undef' );
        my @stdout = split /\n/xsm, $stdout;
        chomp @stdout;
        is( $stdout[0], "?? $home/.files/.config/modules.ini",       '... prints config file' );
        is( $stdout[1], " + $home/.files/additional_module_1",       '... prints additional module' );
        is( $stdout[2], "?? $home/.files/additional_module_2/a.txt", '... prints additional file' );
        is( @stdout,    3,                                           '... no more output' );
        is( $stderr,    q{},                                         '... and nothing to stderr' );
    }

    #
    note('add the file to the Git index');
    $git_module2->add('a.txt');

    {
        my ( $stdout, $stderr, @result ) = capture { $obj->run_status() };
        is( $result[0], undef, 'run_status() returns undef' );
        my @stdout = split /\n/xsm, $stdout;
        chomp @stdout;
        is( $stdout[0], "?? $home/.files/.config/modules.ini",       '... prints config file' );
        is( $stdout[1], " + $home/.files/additional_module_1",       '... prints additional module' );
        is( $stdout[2], "A  $home/.files/additional_module_2/a.txt", '... prints additional file' );
        is( @stdout,    3,                                           '... no more output' );
        is( $stderr,    q{},                                         '... and nothing to stderr' );
    }

    done_testing();

    exit 0;
}

sub _touch {
    my ( $file, @content ) = @_;

    path($file)->spew(@content) or BAIL_OUT("Cannot write file '$file': $!");

    return;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
