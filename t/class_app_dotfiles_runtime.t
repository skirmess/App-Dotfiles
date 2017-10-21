#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::Fatal qw(dies_ok exception);
use Test::More;
use Test::TempDir::Tiny;

use File::Spec;

use App::Dotfiles::Runtime;

main();

sub main {
    my $class = 'App::Dotfiles::Runtime';

    my $home = tempdir();

    #
    note('home_path is required');
    like( exception { $class->new() }, "/ \QMissing required arguments: home_path\E /xsm", q{'home_path' is required during 'new()'} );

    #
    note('defauls');
    my $dotfiles_path = File::Spec->catfile( $home, '.files' );

    my $obj = new_ok( $class, [ home_path => $home ] );

    is( $obj->home_path, $home, q{attribute 'home_path'} );
    dies_ok { $obj->home_path('abc') } '... is a read-only accessor';

    is( $obj->config_dir, '.config', q{attribute 'config_dir'} );
    dies_ok { $obj->config_dir('abc') } '... is a read-only accessor';

    is( $obj->dotfiles_path, $dotfiles_path, q{attribute 'dotfiles_path'} );
    dies_ok { $obj->dotfiles_path('abc') } '... is a read-only accessor';

    is( $obj->modules_config_file, 'modules.ini', q{attribute 'dotfiles_path'} );
    dies_ok { $obj->modules_config_file('abc') } '... is a read-only accessor';

    #
    note('non-defaults');
    $dotfiles_path = tempdir();
    my $config_dir = 'CONFIG_DIR';

    $obj = new_ok( $class, [ home_path => $home, config_dir => $config_dir, dotfiles_path => $dotfiles_path, modules_config_file => 'CONFIG_FILE' ] );

    is( $obj->home_path, $home, q{attribute 'home_path'} );
    dies_ok { $obj->home_path('abc') } '... is a read-only accessor';

    is( $obj->config_dir, $config_dir, q{attribute 'config_dir'} );
    dies_ok { $obj->config_dir('abc') } '... is a read-only accessor';

    is( $obj->dotfiles_path, $dotfiles_path, q{attribute 'dotfiles_path'} );
    dies_ok { $obj->dotfiles_path('abc') } '... is a read-only accessor';

    is( $obj->modules_config_file, 'CONFIG_FILE', q{attribute 'dotfiles_path'} );
    dies_ok { $obj->modules_config_file('abc') } '... is a read-only accessor';

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
