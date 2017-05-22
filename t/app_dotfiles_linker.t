#!perl
use strict;
use warnings;
use autodie;

use Path::Tiny;

use Test::More;
use Test::Fatal;
use Test::TempDir::Tiny;

use Log::Any::Test;
use Log::Any qw($log);

use App::Dotfiles::Runtime;
use App::Dotfiles::Linker;
use App::Dotfiles::Module;

## no critic (RegularExpressions::RequireDotMatchAnything)
## no critic (RegularExpressions::RequireExtendedFormatting)
## no critic (RegularExpressions::RequireLineBoundaryMatching)
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

main();

sub main {
    my $home = path( tempdir() );

    my $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );
    my $mod1 = new_ok( 'App::Dotfiles::Module', [ runtime => $runtime, name => 'mod1', target_path_prefix => 'mod1T' ] );

    my $mod1_path = path( $mod1->module_path );
    $mod1_path->mkpath;
    $mod1_path->child('file.txt')->spew();

    #
    my $linker = new_ok( 'App::Dotfiles::Linker', [ runtime => $runtime ] );

    is( $linker->plan_module($mod1), undef, q{'plan_module' returns undef} );
    my $actions = $linker->_create_actions();

    is( @{$actions}, 1, 'generated one action' );
    my @action = @{ $actions->[0] };
    is( $action[0], 'mod1T', 'correct target' );
    is( $action[1], 'link',  '... action' );
    is( $action[3], q{.},    '... source' );
    isa_ok( $action[2], 'App::Dotfiles::Module' );
    is( $action[2]->name, 'mod1', '... correct module' );

    #
    note('link target blocked by file');
    $linker = new_ok( 'App::Dotfiles::Linker', [ runtime => $runtime ] );

    $home->child('mod1T')->spew();

    is( $linker->plan_module($mod1), undef, q{'plan_module' returns undef} );
    like( exception { $linker->_create_actions() }, qr{Linking module 'mod1' would cause conflicts: link target '.*' is a file but link source '.*' is not}, q{'_create_actions' throws an exception on conflict} );

    unlink $home->child('mod1T');

    #
    note('link target blocked by foreign link');
    $linker = new_ok( 'App::Dotfiles::Linker', [ runtime => $runtime ] );

    symlink tempdir(), $home->child('mod1T');

    is( $linker->plan_module($mod1), undef, q{'plan_module' returns undef} );
    like( exception { $linker->_create_actions() }, qr{Linking module 'mod1' would cause conflicts: link target '.*' is a symlink that is not managed by us}, q{'_create_actions' throws an exception on conflict} );

    unlink $home->child('mod1T');

    #
    note('link target blocked by our link');
    $linker = new_ok( 'App::Dotfiles::Linker', [ runtime => $runtime ] );

    symlink $mod1_path, $home->child('mod1T');

    is( $linker->plan_module($mod1), undef, q{'plan_module' returns undef} );
    $actions = $linker->_create_actions();

    is( @{$actions}, 2, 'generated two actions' );

    @action = @{ $actions->[0] };
    is( $action[0], 'mod1T',  'correct target' );
    is( $action[1], 'unlink', '... action' );

    @action = @{ $actions->[1] };
    is( $action[0], 'mod1T', 'correct target' );
    is( $action[1], 'link',  '... action' );
    is( $action[3], q{.},    '... source' );
    isa_ok( $action[2], 'App::Dotfiles::Module' );
    is( $action[2]->name, 'mod1', '... correct module' );

    unlink $home->child('mod1T');

    #
    note('link target blocked by our dead link');
    $linker = new_ok( 'App::Dotfiles::Linker', [ runtime => $runtime ] );

    symlink $mod1_path->child('a/b c/d'), $home->child('mod1T');

    is( $linker->plan_module($mod1), undef, q{'plan_module' returns undef} );
    $actions = $linker->_create_actions();

    is( @{$actions}, 2, 'generated two actions' );

    @action = @{ $actions->[0] };
    is( $action[0], 'mod1T',  'correct target' );
    is( $action[1], 'unlink', '... action' );

    @action = @{ $actions->[1] };
    is( $action[0], 'mod1T', 'correct target' );
    is( $action[1], 'link',  '... action' );
    is( $action[3], q{.},    '... source' );
    isa_ok( $action[2], 'App::Dotfiles::Module' );
    is( $action[2]->name, 'mod1', '... correct module' );

    unlink $home->child('mod1T');

    #
    note('correct link exists already');
    $linker = new_ok( 'App::Dotfiles::Linker', [ runtime => $runtime ] );

    symlink path('.files/mod1'), $home->child('mod1T');

    is( $linker->plan_module($mod1), undef, q{'plan_module' returns undef} );
    $actions = $linker->_create_actions();

    is( @{$actions}, 0, 'generated zero actions' );

    unlink $home->child('mod1T');

    #
    note('link target is a directory');
    $linker = new_ok( 'App::Dotfiles::Linker', [ runtime => $runtime ] );

    $home->child('mod1T')->mkpath();

    is( $linker->plan_module($mod1), undef, q{'plan_module' returns undef} );
    $actions = $linker->_create_actions();

    is( @{$actions}, 1, 'generated one action' );
    @action = @{ $actions->[0] };
    is( $action[0], path('mod1T/file.txt'), 'correct target' );
    is( $action[1], 'link',                 '... action' );
    is( $action[3], 'file.txt',             '... source' );
    isa_ok( $action[2], 'App::Dotfiles::Module' );
    is( $action[2]->name, 'mod1', '... correct module' );

    rmdir $home->child('mod1T');

    #
    note('check the sanity check');
    $linker = new_ok( 'App::Dotfiles::Linker', [ runtime => $runtime ] );
    my $dirs  = $linker->_dirs;
    my $links = $linker->_links;

    $dirs->{test}  = 1;
    $links->{test} = 1;

    $linker->plan_module($mod1);
    like( exception { $linker->_create_actions() }, qr{internal error: '_dirs' and '_links' both contain a 'test' at}, 'internal error throws' );

    #
    note('multi directory target_path_prefix');
    $mod1 = new_ok( 'App::Dotfiles::Module', [ runtime => $runtime, name => 'mod1', target_path_prefix => path('mod1Ta/MOD 1 T')->stringify() ] );

    $linker = new_ok( 'App::Dotfiles::Linker', [ runtime => $runtime ] );

    is( $linker->plan_module($mod1), undef, q{'plan_module' returns undef} );
    $actions = $linker->_create_actions();

    is( @{$actions}, 2, 'generated two actions' );

    @action = @{ $actions->[0] };
    is( $action[0], 'mod1Ta', 'correct target' );
    is( $action[1], 'mkdir',  '... action' );

    @action = @{ $actions->[1] };
    is( $action[0], path('mod1Ta/MOD 1 T'), 'correct target' );
    is( $action[1], 'link',                 '... action' );
    is( $action[3], q{.},                   '... source' );
    isa_ok( $action[2], 'App::Dotfiles::Module' );
    is( $action[2]->name, 'mod1', '... correct module' );

    #
    note('link target blocked by file that can be moved');
    $linker = new_ok( 'App::Dotfiles::Linker', [ runtime => $runtime ] );

    $home->path('mod1Ta/MOD 1 T')->mkpath();
    $home->path('mod1Ta/MOD 1 T/file.txt')->spew();

    is( $linker->plan_module($mod1), undef, q{'plan_module' returns undef} );
    $actions = $linker->_create_actions();

    is( @{$actions}, 2, 'generated two actions' );

    @action = @{ $actions->[0] };
    is( $action[0], path('mod1Ta/MOD 1 T/file.txt'), 'correct target' );
    is( $action[1], 'move',                          '... action' );
    is( $action[3], 'file.txt',                      '... source' );
    isa_ok( $action[2], 'App::Dotfiles::Module' );
    is( $action[2]->name, 'mod1', '... correct module' );

    @action = @{ $actions->[1] };
    is( $action[0], path('mod1Ta/MOD 1 T/file.txt'), 'correct target' );
    is( $action[1], 'link',                          '... action' );
    is( $action[3], 'file.txt',                      '... source' );
    isa_ok( $action[2], 'App::Dotfiles::Module' );
    is( $action[2]->name, 'mod1', '... correct module' );

    #
    note('multiple modules');
    $home = path( tempdir() );

    $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

    $linker = new_ok( 'App::Dotfiles::Linker', [ runtime => $runtime ] );

    my @mod;
    $mod[0] = new_ok( 'App::Dotfiles::Module', [ runtime => $runtime, name => 'mod0A' ] );
    $mod[1] = new_ok( 'App::Dotfiles::Module', [ runtime => $runtime, name => 'mod1A' ] );
    $mod[2] = new_ok( 'App::Dotfiles::Module', [ runtime => $runtime, name => 'mod2A', source_path_prefix => 'abc' ] );
    $mod[3] = new_ok( 'App::Dotfiles::Module', [ runtime => $runtime, name => 'mod3A', source_path_prefix => path('abc/xyz') ] );

    my @mod_path;
    for my $i ( 0 .. 3 ) {
        $mod_path[$i] = path( $mod[$i]->module_path );
        $mod_path[$i]->mkpath;
    }

    $mod_path[0]->child('file0')->spew();
    $mod_path[0]->child('dir')->mkpath();
    $mod_path[0]->child('dir/file0.txt')->spew();

    $mod_path[1]->child('file1')->spew();
    $mod_path[1]->child('dir')->mkpath();
    $mod_path[1]->child('dir/file1.txt')->spew();

    $mod_path[2]->child('abc/dir')->mkpath();
    $mod_path[2]->child('abc/dir/file2.txt')->spew();

    $mod_path[3]->child('abc/xyz/dir')->mkpath();
    $mod_path[3]->child('abc/xyz/dir/file3.txt')->spew();

    for my $i ( 0 .. 3 ) {
        is( $linker->plan_module( $mod[$i] ), undef, q{'plan_module' returns undef} );
    }
    $actions = $linker->_create_actions();

    is( @{$actions}, 7, 'generated seven actions' );

    @action = @{ $actions->[0] };
    is( $action[0], 'dir',   'correct target' );
    is( $action[1], 'mkdir', '... action' );

    @action = @{ $actions->[1] };
    is( $action[0], path('dir/file0.txt'), 'correct target' );
    is( $action[1], 'link',                '... action' );
    is( $action[3], 'dir/file0.txt',       '... source' );
    isa_ok( $action[2], 'App::Dotfiles::Module' );
    is( $action[2]->name, 'mod0A', '... correct module' );

    @action = @{ $actions->[2] };
    is( $action[0], path('dir/file1.txt'), 'correct target' );
    is( $action[1], 'link',                '... action' );
    is( $action[3], 'dir/file1.txt',       '... source' );
    isa_ok( $action[2], 'App::Dotfiles::Module' );
    is( $action[2]->name, 'mod1A', '... correct module' );

    @action = @{ $actions->[3] };
    is( $action[0], path('dir/file2.txt'), 'correct target' );
    is( $action[1], 'link',                '... action' );
    is( $action[3], 'dir/file2.txt',       '... source' );
    isa_ok( $action[2], 'App::Dotfiles::Module' );
    is( $action[2]->name, 'mod2A', '... correct module' );

    @action = @{ $actions->[4] };
    is( $action[0], path('dir/file3.txt'), 'correct target' );
    is( $action[1], 'link',                '... action' );
    is( $action[3], 'dir/file3.txt',       '... source' );
    isa_ok( $action[2], 'App::Dotfiles::Module' );
    is( $action[2]->name, 'mod3A', '... correct module' );

    @action = @{ $actions->[5] };
    is( $action[0], 'file0', 'correct target' );
    is( $action[1], 'link',  '... action' );
    is( $action[3], 'file0', '... source' );
    isa_ok( $action[2], 'App::Dotfiles::Module' );
    is( $action[2]->name, 'mod0A', '... correct module' );

    @action = @{ $actions->[6] };
    is( $action[0], 'file1', 'correct target' );
    is( $action[1], 'link',  '... action' );
    is( $action[3], 'file1', '... source' );
    isa_ok( $action[2], 'App::Dotfiles::Module' );
    is( $action[2]->name, 'mod1A', '... correct module' );

    #
    note('multiple modules with target_path_prefix');
    $home = path( tempdir() );

    $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

    @mod = ();
    $mod[0] = new_ok( 'App::Dotfiles::Module', [ runtime => $runtime, name => 'module1', target_path_prefix => path('target/T') ] );
    $mod[1] = new_ok( 'App::Dotfiles::Module', [ runtime => $runtime, name => 'module2', target_path_prefix => path('target/T') ] );

    @mod_path = ();
    for my $i ( 0 .. 1 ) {
        $mod_path[$i] = path( $mod[$i]->module_path );
        $mod_path[$i]->mkpath();
    }

    $linker = new_ok( 'App::Dotfiles::Linker', [ runtime => $runtime ] );

    is( $linker->plan_module( $mod[0] ), undef, q{'plan_module' returns undef} );
    is( $linker->plan_module( $mod[1] ), undef, q{'plan_module' returns undef} );
    $actions = $linker->_create_actions();

    is( @{$actions}, 2, 'generated two actions' );

    @action = @{ $actions->[0] };
    is( $action[0], 'target', 'correct target' );
    is( $action[1], 'mkdir',  '... action' );

    @action = @{ $actions->[1] };
    is( $action[0], 'target/T', 'correct target' );
    is( $action[1], 'mkdir',    '... action' );

    #
    note('dir target blocked by foreign link');

    $home = path( tempdir() );
    $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

    $linker = new_ok( 'App::Dotfiles::Linker', [ runtime => $runtime ] );

    @mod = ();
    $mod[0] = new_ok( 'App::Dotfiles::Module', [ runtime => $runtime, name => 'module1', target_path_prefix => path('target/T') ] );
    $mod[1] = new_ok( 'App::Dotfiles::Module', [ runtime => $runtime, name => 'module2', target_path_prefix => path('target/T') ] );

    @mod_path = ();
    for my $i ( 0 .. 1 ) {
        $mod_path[$i] = path( $mod[$i]->module_path );
        $mod_path[$i]->mkpath();
    }

    symlink tempdir(), $home->child('target');

    is( $linker->plan_module( $mod[0] ), undef, q{'plan_module' returns undef} );
    is( $linker->plan_module( $mod[1] ), undef, q{'plan_module' returns undef} );

    like( exception { $linker->_create_actions() }, qr{Linking module 'module1' would cause conflicts: link target '.*' is a symlink that is not managed by us}, q{'_create_actions' throws an exception on conflict} );

    unlink $home->child('target');

    #
    note('dir target blocked by our link');
    $linker = new_ok( 'App::Dotfiles::Linker', [ runtime => $runtime ] );

    symlink $mod_path[0], $home->child('target');

    is( $linker->plan_module( $mod[0] ), undef, q{'plan_module' returns undef} );
    is( $linker->plan_module( $mod[1] ), undef, q{'plan_module' returns undef} );
    $actions = $linker->_create_actions();

    is( @{$actions}, 3, 'generated three actions' );

    @action = @{ $actions->[0] };
    is( $action[0], 'target', 'correct target' );
    is( $action[1], 'unlink', '... action' );

    @action = @{ $actions->[1] };
    is( $action[0], 'target', 'correct target' );
    is( $action[1], 'mkdir',  '... action' );

    @action = @{ $actions->[2] };
    is( $action[0], 'target/T', 'correct target' );
    is( $action[1], 'mkdir',    '... action' );

    unlink $home->child('target');

    #
    note('fitting run restart');

    $home = path( tempdir() );
    $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

    $linker = new_ok( 'App::Dotfiles::Linker', [ runtime => $runtime ] );

    @mod = ();
    $mod[0] = new_ok( 'App::Dotfiles::Module', [ runtime => $runtime, name => 'module0' ] );
    $mod[1] = new_ok( 'App::Dotfiles::Module', [ runtime => $runtime, name => 'module1' ] );

    @mod_path = ();
    for my $i ( 0 .. 1 ) {
        $mod_path[$i] = path( $mod[$i]->module_path );
        $mod_path[$i]->mkpath();
    }

    $mod_path[0]->child('dir1')->mkpath();
    $mod_path[1]->child('dir2')->mkpath();

    $mod_path[0]->child('dir1/file0.txt')->spew();
    $mod_path[1]->child('dir2/file1.txt')->spew();

    $home->child('dir2')->mkpath();

    is( $linker->plan_module( $mod[0] ), undef, q{'plan_module' returns undef} );
    $actions = $linker->_create_actions();

    is( @{$actions}, 1, 'generated one action' );

    @action = @{ $actions->[0] };
    is( $action[0], path('dir1'), 'correct target' );
    is( $action[1], 'link',       '... action' );
    is( $action[3], 'dir1',       '... source' );
    isa_ok( $action[2], 'App::Dotfiles::Module' );
    is( $action[2]->name, 'module0', '... correct module' );

    is( $linker->plan_module( $mod[1] ), undef, q{'plan_module' returns undef} );
    $actions = $linker->_create_actions();

    is( @{$actions}, 2, 'generated two actions' );

    @action = @{ $actions->[0] };
    is( $action[0], path('dir1'), 'correct target' );
    is( $action[1], 'link',       '... action' );
    is( $action[3], 'dir1',       '... source' );
    isa_ok( $action[2], 'App::Dotfiles::Module' );
    is( $action[2]->name, 'module0', '... correct module' );

    @action = @{ $actions->[1] };
    is( $action[0], path('dir2/file1.txt'), 'correct target' );
    is( $action[1], 'link',                 '... action' );
    is( $action[3], 'dir2/file1.txt',       '... source' );
    isa_ok( $action[2], 'App::Dotfiles::Module' );
    is( $action[2]->name, 'module1', '... correct module' );

    #
    note('link two modules');
    $home = path( tempdir() );
    $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

    @mod = ();
    $mod[0] = new_ok( 'App::Dotfiles::Module', [ runtime => $runtime, name => 'vim' ] );
    $mod[1] = new_ok( 'App::Dotfiles::Module', [ runtime => $runtime, name => 'vim-plugin', target_path_prefix => path('.vim/bundle/vim-plugin') ] );

    @mod_path = ();
    for my $i ( 0 .. 1 ) {
        $mod_path[$i] = path( $mod[$i]->module_path );
        $mod_path[$i]->mkpath();
    }

    $mod_path[0]->child('.vimrc')->spew();

    $mod_path[1]->child('plugin')->mkpath();
    $mod_path[1]->child('plugin/plugin.vim')->spew();

    for my $i ( 'first', 'second', 'third', 'fourth', 'fifth' ) {
        note("$i run");
        $linker = new_ok( 'App::Dotfiles::Linker', [ runtime => $runtime ] );

        is( $linker->plan_module( $mod[0] ), undef, q{'plan_module' returns undef} );
        is( $linker->plan_module( $mod[1] ), undef, q{'plan_module' returns undef} );
        is( $linker->run(),                  undef, q{'link' returns undef} );

        ok( -l $home->child('.vimrc'), q{File '.vimrc' is a link} );
        is( readlink $home->child('.vimrc'), '.files/vim/.vimrc', '... pointing to the correct file' );

        ok( -d $home->child('.vim'),                   q{File '.vim' is a directory} );
        ok( -d $home->child('.vim/bundle'),            q{File '.vim/bundle' is a directory} );
        ok( -l $home->child('.vim/bundle/vim-plugin'), q{File '.vim/bundle/vim-plugin' is a link} );
        is( readlink $home->child('.vim/bundle/vim-plugin'), '../../.files/vim-plugin', '... pointing to the correct file' );

        if ( $i eq 'second' ) {
            unlink $home->child('.vimrc');
        }

        if ( $i eq 'third' ) {
            unlink $home->child('.vimrc');
            symlink $mod_path[1], $home->child('.vimrc');
        }

        if ( $i eq 'fourth' ) {
            unlink $home->child('.vimrc');
            $home->child('.vimrc')->spew('hello world');
        }
    }

    my $x = $home->child('.vimrc')->slurp();
    is( $x, 'hello world', '.vimrc was correctly moved back into module' );

    #
    note('home is reached through symlink');
    my $tmpdir = path( tempdir() )->child('home');
    $home = path( tempdir() )->child('HOME');
    $tmpdir->mkpath();
    symlink $tmpdir, $home;

    $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

    $mod1 = new_ok( 'App::Dotfiles::Module', [ runtime => $runtime, name => 'mod1' ] );

    $mod1_path = path( $mod1->module_path );
    $mod1_path->mkpath;
    $mod1_path->child('file.txt')->spew();

    $linker = new_ok( 'App::Dotfiles::Linker', [ runtime => $runtime ] );
    $linker->plan_module($mod1);
    $linker->run();

    # Run linker again, we should not correctly identify the symlink
    #   file.txt -> .files/mod1/file.txt
    # as ours. This might fail because home is reached through a symlink.
    $linker = new_ok( 'App::Dotfiles::Linker', [ runtime => $runtime ] );
    $linker->plan_module($mod1);
    is( exception { $linker->run() }, undef, 'Running linker again correctly identifies the symlink created in the last run as our. (home is reached through a symlink)' );

    #
    $log->empty_ok('nothing was logged');

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
