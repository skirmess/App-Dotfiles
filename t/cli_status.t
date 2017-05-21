#!perl
use strict;
use warnings;
use autodie;

use Carp;

use Test::Fatal;
use Test::More;
use Test::TempDir::Tiny;

use File::Path qw(make_path);
use File::Spec;

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

    my $runtime = new_ok( 'App::Dotfiles::Runtime',      [ home_path => $home ] );
    my $obj     = new_ok( 'App::Dotfiles::CLI::Command', [ runtime   => $runtime ] );

    #
    note('~/.files does not exist');
    isa_ok( exception { $obj->run_status() }, 'App::Dotfiles::Error::E_NO_CONFIG_REPOSITORY', 'run_status() throws an exception when the config dir does not exist.' );
    $log->empty_ok('... log is empty');

    #
    note('~/.files/.config exists but is not a Git repository');
    my $config_path = File::Spec->catfile( $home, '.files', '.config' );
    make_path( File::Spec->catfile( $config_path, '.git' ) );

    my $config_dir_path_qm = quotemeta File::Spec->catfile( $home, '.files', '.config' );

    like( exception { $obj->run_status() }, qr{Directory '$config_dir_path_qm' exists but is not a valid Git directory}, '... throws an axception when the config dir exists but is not a Git repository' );
    $log->empty_ok('... log is empty');

    #
    note('~/.files/.config exists and is a Git repository');
    my $git = Git::Wrapper->new($config_path);
    $git->init();

    my $config_file_path_qm = quotemeta File::Spec->catfile( $home, '.files', '.config', 'modules.ini' );

    like( exception { $obj->run_status() }, qr{Missing config file '$config_file_path_qm'}, 'run_status() throws an error if the config file is missing' );
    $log->empty_ok('... log is empty');

    #
    note('add config file');
    my $config_file = File::Spec->catfile( $home, '.files', '.config', 'modules.ini' );
    open my $fh, '>', $config_file;
    close $fh;

    is( $obj->run_status(), undef, 'run_status() returns undef with empty config file' );
    $log->contains_ok( qr{[?][?] $config_file_path_qm}, '... logs the not-commited config file' );
    $log->empty_ok('... no more logs');

    #
    note('one additional module (present, but not in config)');
    make_path( File::Spec->catfile( $home, '.files', 'additional_module_1' ) );

    is( $obj->run_status(), undef, 'run_status() returns undef' );
    $log->contains_ok( qr{[?][?] $config_file_path_qm},             '... logs config file' );
    $log->contains_ok( qr{ [+] $home/[.]files/additional_module_1}, '... logs additional module' );
    $log->empty_ok('... no more logs');

    #
    note('add additional module to config file');
    open $fh, '>', $config_file;
    _print( $fh, "[additional_module_1]\npull=http://www.example.net/test.git\n" );
    close $fh;

    is( $obj->run_status(), undef, 'run_status() returns undef' );
    $log->contains_ok( qr{[?][?] $home/[.]files/[.]config/modules[.]ini}, '... logs config file' );
    $log->contains_ok( qr{ [~] $home/[.]files/additional_module_1},       '... logs additional module' );
    $log->empty_ok('... no more logs');

    #
    note('mention another module in config file');
    open $fh, '>', $config_file;
    _print( $fh, "[additional_module_2]\npull=http://www.example.net/test.git\n" );
    close $fh;

    is( $obj->run_status(), undef, 'run_status() returns undef' );
    $log->contains_ok( qr{[?][?] $home/[.]files/[.]config/modules[.]ini}, '... logs config file' );
    $log->contains_ok( qr{ [+] $home/[.]files/additional_module_1},       '... logs additional module' );
    $log->contains_ok( qr{ [-] $home/[.]files/additional_module_2},       '... logs missing module' );
    $log->empty_ok('... no more logs');

    #
    note('one additional module, one git repository');
    my $module2_path = File::Spec->catfile( $home, '.files', 'additional_module_2' );
    make_path($module2_path);
    my $git_module2 = Git::Wrapper->new($module2_path);
    $git_module2->init();

    is( $obj->run_status(), undef, 'run_status() returns undef' );
    $log->contains_ok( qr{[?][?] $home/[.]files/[.]config/modules[.]ini}, '... logs config file' );
    $log->contains_ok( qr{ [+] $home/[.]files/additional_module_1},       '... logs additional module' );
    $log->empty_ok('... no more logs');

    #
    note('add changes to module2');
    open $fh, '>', File::Spec->catfile( $module2_path, 'a.txt' );
    close $fh;

    is( $obj->run_status(), undef, 'run_status() returns undef' );
    $log->contains_ok( qr{[?][?] $home/[.]files/[.]config/modules[.]ini},     '... logs config file' );
    $log->contains_ok( qr{ [+] $home/[.]files/additional_module_1},           '... logs additional module' );
    $log->contains_ok( qr{[?][?] $home/[.]files/additional_module_2/a[.]txt}, '... logs additional file' );
    $log->empty_ok('... no more logs');

    #
    note('add the file to the Git index');
    $git_module2->add('a.txt');

    is( $obj->run_status(), undef, 'run_status() returns undef' );
    $log->contains_ok( qr{[?][?] $home/[.]files/[.]config/modules[.]ini}, '... logs config file' );
    $log->contains_ok( qr{ [+] $home/[.]files/additional_module_1},       '... logs additional module' );
    $log->contains_ok( qr{A  $home/[.]files/additional_module_2/a[.]txt}, '... logs additional file' );
    $log->empty_ok('... no more logs');

    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
