#!perl

use 5.006;
use strict;
use warnings;

use Carp;

use File::Path qw(make_path);
use File::Spec;
use Path::Tiny;

use Test::Fatal;
use Test::More;
use Test::TempDir::Tiny;

use App::Dotfiles::Runtime;
use App::Dotfiles::Module::Config;

main();

sub main {
    my $home = tempdir();

    my $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

    #
    my $class = 'App::Dotfiles::Module::Config';
    my $obj = new_ok( $class, [ runtime => $runtime ] );

    #
    note('get_modules() throws an error if no modules.ini file exists');
    my $config_file_path = File::Spec->catfile( $home, '.files', '.config', 'modules.ini' );
    like( exception { $obj->get_modules() }, "/ \QMissing config file '$config_file_path'\E /xsm", 'get_modules() throws an exception if there is no config file' );

    #
    note('empty config file');
    make_path( File::Spec->catfile( $home, '.files', '.config' ) );
    my $modules_file = File::Spec->catfile( $home, '.files', '.config', 'modules.ini' );
    _touch($modules_file);

    my @modules = $obj->get_modules();
    is( @modules, 0, '... returns an empty list if there are no modules mentioned in the modules.ini file' );

    #
    note('entries in global section in config file');
    _touch( $modules_file, <<'EOF');
pull=http://example.net/test.git
EOF

    like( exception { $obj->get_modules() }, "/ \QError in configuration file '$config_file_path': global section not allowed\E /xsm", '... throws an exception if there are entries in the glonal section' );

    #
    note('pull specified multiple times');
    _touch( $modules_file, <<'EOF');
[test]
pull=http://example.net/test.git
pull=http://example.net/test.git
EOF

    like( exception { $obj->get_modules() }, "/ \Q'pull' url defined multiple times in section '[test]'\E /xsm", '... throws an exception if pull URL is defined multiple times an a section' );

    #
    note('push specified multiple times');
    _touch( $modules_file, <<'EOF');
[test]
push=http://example.net/test.git
push=http://example.net/test.git
EOF

    like( exception { $obj->get_modules() }, "/ \Q'push' url defined multiple times in section '[test]'\E /xsm", '... throws an exception if push URL is defined multiple times an a section' );

    #
    note(q{'target path prefix' specified multiple times});
    _touch( $modules_file, <<'EOF');
[test]
target path prefix = a/b/c
target path prefix = a/b/c
EOF

    like( exception { $obj->get_modules() }, "/ \Q'target path prefix' defined multiple times in section '[test]'\E /xsm", q{... throws an exception if 'target path url' is defined multiple times an a section} );

    #
    note(q{'source path prefix' specified multiple times});
    _touch( $modules_file, <<'EOF');
[test]
source path prefix = a/b/c
source path prefix = a/b/c
EOF

    like( exception { $obj->get_modules() }, "/ \Q'source path prefix' defined multiple times in section '[test]'\E /xsm", q{... throws an exception if 'source path url' is defined multiple times an a section} );

    # invalid entry (key w/out value)
    _touch( $modules_file, <<'EOF');
[test]
push=http://example.net/test.git
invalid
EOF

    # error thrown is from Config::Std
    like( exception { $obj->get_modules() }, "/ \QError in config file\E /xsm", '... throws an exception if there is an error in the config file' );

    #
    note('invalid entry');
    _touch( $modules_file, <<'EOF');
[test]
push=http://example.net/test.git
invalid=entry
EOF

    like( exception { $obj->get_modules() }, "/ \QInvalid entry 'invalid=entry' in section '[test]'\E /xsm", '... throws an exception if there is an invalid entry' );

    # multiple invalid entries
    _touch( $modules_file, <<'EOF');
[test]
push=http://example.net/test.git
invalid=entry
invalid=entry2
EOF

    like( exception { $obj->get_modules() }, "/ \QInvalid entry with key 'invalid' in section '[test]'\E /xsm", '... throws an exception if there are multiple invalid entries' );

    #
    note('push w/out pull entry');
    _touch( $modules_file, <<'EOF');
[test]
push=http://example.net/test.git
EOF

    like( exception { $obj->get_modules() }, "/ \QPull url not defined in section '[test]'\E /xsm", '... throws an exception if there is no pull url' );

    # section w/out entries
    _touch( $modules_file, <<'EOF');
[test]
EOF

    like( exception { $obj->get_modules() }, "/ \QPull url not defined in section '[test]'\E /xsm", '... throws an exception if there is no pull url' );

    #
    note('one module');
    _touch( $modules_file, <<'EOF');
[test]
pull=http://example.net/test.git
EOF

    @modules = $obj->get_modules();
    is( @modules, 1, '... returns a list of one object' );
    isa_ok( $modules[0], 'App::Dotfiles::Module' );
    is( $modules[0]->name, 'test', '... has the correct name' );

    #
    note('two module');
    _touch( $modules_file, <<'EOF');
[test]
pull=http://example.net/test.git
[test2]
pull=http://example.net/test2.git
EOF

    @modules = $obj->get_modules();
    is( @modules, 2, '... returns a list of two object' );
    isa_ok( $modules[0], 'App::Dotfiles::Module' );
    isa_ok( $modules[1], 'App::Dotfiles::Module' );
    is( $modules[0]->name,               'test',                         '... the first has the correct name' );
    is( $modules[1]->name,               'test2',                        '... the second has the correct name' );
    is( $modules[0]->pull_url,           'http://example.net/test.git',  '... the first has the correct pull url' );
    is( $modules[0]->push_url,           undef,                          '... undef push url' );
    is( $modules[1]->pull_url,           'http://example.net/test2.git', '... the second has the correct pull url' );
    is( $modules[1]->push_url,           undef,                          '... undef push url' );
    is( $modules[0]->source_path_prefix, q{.},                           '... the first has the correct default source_path_prefix' );
    isa_ok( $modules[0]->source_path_prefix, 'Path::Tiny' );
    is( $modules[0]->target_path_prefix, q{.}, '... default target_path_prefix' );
    isa_ok( $modules[0]->target_path_prefix, 'Path::Tiny' );
    is( $modules[1]->source_path_prefix, q{.}, '... the second has the correct default source_path_prefix' );
    isa_ok( $modules[1]->source_path_prefix, 'Path::Tiny' );
    is( $modules[1]->target_path_prefix, q{.}, '... default target_path_prefix' );
    isa_ok( $modules[1]->target_path_prefix, 'Path::Tiny' );

    #
    note(q{four modules with 'source path prefix' / 'target path prefix'});
    _touch( $modules_file, <<'EOF');
[test1]
pull=http://example.net/test1.git
[test2]
pull=http://example.net/test2.git
source path prefix=a/b c/d
[test3]
pull=http://example.net/test3.git
target path prefix=x/y/z
[test4]
pull=http://example.net/test4.git
source path prefix=A
target path prefix=B
EOF

    @modules = $obj->get_modules();
    is( @modules, 4, '... returns a list of four object' );
    isa_ok( $modules[0], 'App::Dotfiles::Module' );
    isa_ok( $modules[1], 'App::Dotfiles::Module' );
    isa_ok( $modules[2], 'App::Dotfiles::Module' );
    isa_ok( $modules[3], 'App::Dotfiles::Module' );
    is( $modules[0]->name,               'test1',                        '... the first has the correct name' );
    is( $modules[1]->name,               'test2',                        '... the second has the correct name' );
    is( $modules[2]->name,               'test3',                        '... the third has the correct name' );
    is( $modules[3]->name,               'test4',                        '... the fourth has the correct name' );
    is( $modules[0]->pull_url,           'http://example.net/test1.git', '... the first has the correct pull url' );
    is( $modules[0]->push_url,           undef,                          '... undef push url' );
    is( $modules[1]->pull_url,           'http://example.net/test2.git', '... the second has the correct pull url' );
    is( $modules[1]->push_url,           undef,                          '... undef push url' );
    is( $modules[2]->pull_url,           'http://example.net/test3.git', '... the third has the correct pull url' );
    is( $modules[2]->push_url,           undef,                          '... undef push url' );
    is( $modules[3]->pull_url,           'http://example.net/test4.git', '... the fourth has the correct pull url' );
    is( $modules[3]->push_url,           undef,                          '... undef push url' );
    is( $modules[0]->source_path_prefix, q{.},                           '... the first has the correct default source_path_prefix' );
    isa_ok( $modules[0]->source_path_prefix, 'Path::Tiny' );
    is( $modules[0]->target_path_prefix, q{.}, '... default target_path_prefix' );
    isa_ok( $modules[0]->target_path_prefix, 'Path::Tiny' );
    is( $modules[1]->source_path_prefix, path('a/b c/d'), '... the second has the correct source_path_prefix' );
    isa_ok( $modules[1]->source_path_prefix, 'Path::Tiny' );
    is( $modules[1]->target_path_prefix, q{.}, '... default target_path_prefix' );
    isa_ok( $modules[1]->target_path_prefix, 'Path::Tiny' );
    is( $modules[2]->source_path_prefix, q{.}, '... the third has the correct default source_path_prefix' );
    isa_ok( $modules[2]->source_path_prefix, 'Path::Tiny' );
    is( $modules[2]->target_path_prefix, path('x/y/z'), '... target_path_prefix' );
    isa_ok( $modules[2]->target_path_prefix, 'Path::Tiny' );
    is( $modules[3]->source_path_prefix, 'A', '... the fourth has the correct source_path_prefix' );
    isa_ok( $modules[3]->source_path_prefix, 'Path::Tiny' );
    is( $modules[3]->target_path_prefix, 'B', '... target_path_prefix' );
    isa_ok( $modules[3]->target_path_prefix, 'Path::Tiny' );

    #
    note('two modules w/ push url');
    _touch( $modules_file, <<'EOF');
[test]
pull=http://example.net/test.git
push=http://example.net/test3.git
[test2]
pull=http://example.net/test2.git
push=http://example.net/test4.git
EOF

    @modules = $obj->get_modules();
    is( @modules, 2, '... returns a list of two object' );
    isa_ok( $modules[0], 'App::Dotfiles::Module' );
    isa_ok( $modules[1], 'App::Dotfiles::Module' );
    is( $modules[0]->name,     'test',                         '... the first has the correct name' );
    is( $modules[1]->name,     'test2',                        '... the second has the correct name' );
    is( $modules[0]->pull_url, 'http://example.net/test.git',  '... the first has the correct pull url' );
    is( $modules[0]->push_url, 'http://example.net/test3.git', '... push url' );
    is( $modules[1]->pull_url, 'http://example.net/test2.git', '... the second has the correct pull url' );
    is( $modules[1]->push_url, 'http://example.net/test4.git', '... push url' );

    #
    done_testing();

    exit 0;
}

sub _touch {
    my ( $file, @content ) = @_;

    path($file)->spew(@content) or BAIL_OUT("Cannot write file '$file': $!");

    return;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
