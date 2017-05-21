#!perl
use strict;
use warnings;
use autodie;

use Carp;

use File::Path qw(make_path);
use File::Spec;
use Path::Tiny;

use Test::Fatal;
use Test::More;
use Test::TempDir::Tiny;

use App::Dotfiles::Runtime;
use App::Dotfiles::Module::Config;

## no critic (InputOutput::RequireBriefOpen)
## no critic (RegularExpressions::RequireDotMatchAnything)
## no critic (RegularExpressions::RequireExtendedFormatting)
## no critic (RegularExpressions::RequireLineBoundaryMatching)
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

main();

sub _print {
    my ( $fh, @args ) = @_;

    print {$fh} @args or croak qq{$!};
    return;
}

sub main {

    # untaint
    my ($home) = tempdir() =~ m{ (.*) }xms;
    local ( $ENV{PATH} ) = $ENV{PATH} =~ m{ (.*) }xms;

    my $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

    #
    my $class = 'App::Dotfiles::Module::Config';
    my $obj = new_ok( $class, [ runtime => $runtime ] );

    #
    note('get_modules() throws an error if no modules.ini file exists');
    my $config_file_path_qm = quotemeta File::Spec->catfile( $home, '.files', '.config', 'modules.ini' );
    like( exception { $obj->get_modules() }, qr{Missing config file '$config_file_path_qm'}, 'get_modules() throws an exception if there is no config file' );

    #
    note('empty config file');
    make_path( File::Spec->catfile( $home, '.files', '.config' ) );
    my $modules_file = File::Spec->catfile( $home, '.files', '.config', 'modules.ini' );
    open my $fh, '>', "$modules_file";
    close $fh;

    my @modules = $obj->get_modules();
    is( @modules, 0, '... returns an empty list if there are no modules mentioned in the modules.ini file' );

    #
    note('entries in global section in config file');
    open $fh, '>', "$modules_file";
    _print( $fh, "pull=http://example.net/test.git\n" );
    close $fh;

    like( exception { $obj->get_modules() }, qr{Error in configuration file '$config_file_path_qm': global section not allowed}, '... throws an exception if there are entries in the glonal section' );

    #
    note('pull specified multiple times');
    open $fh, '>', "$modules_file";
    _print( $fh, "[test]\n" );
    _print( $fh, "pull=http://example.net/test.git\n" );
    _print( $fh, "pull=http://example.net/test.git\n" );
    close $fh;

    like( exception { $obj->get_modules() }, qr{Pull url defined multiple times in section '\[test\]'}, '... throws an exception if pull URL is defined multiple times an a section' );

    #
    note('push specified multiple times');
    open $fh, '>', "$modules_file";
    _print( $fh, "[test]\n" );
    _print( $fh, "push=http://example.net/test.git\n" );
    _print( $fh, "push=http://example.net/test.git\n" );
    close $fh;

    like( exception { $obj->get_modules() }, qr{Push url defined multiple times in section '\[test\]'}, '... throws an exception if push URL is defined multiple times an a section' );

    # invalid entry (key w/out value)
    open $fh, '>', "$modules_file";
    _print( $fh, "[test]\n" );
    _print( $fh, "push=http://example.net/test.git\n" );
    _print( $fh, "invalid\n" );
    close $fh;

    # error thrown is from Config::Std
    like( exception { $obj->get_modules() }, qr{Error in config file}, '... throws an exception if there is an error in the config file' );

    #
    note('invalid entry');
    open $fh, '>', "$modules_file";
    _print( $fh, "[test]\n" );
    _print( $fh, "push=http://example.net/test.git\n" );
    _print( $fh, "invalid=entry\n" );
    close $fh;

    like( exception { $obj->get_modules() }, qr{Invalid entry 'invalid=entry' in section '\[test\]'}, '... throws an exception if there is an invalid entry' );

    # multiple invalid entries
    open $fh, '>', "$modules_file";
    _print( $fh, "[test]\n" );
    _print( $fh, "push=http://example.net/test.git\n" );
    _print( $fh, "invalid=entry\n" );
    _print( $fh, "invalid=entry2\n" );
    close $fh;

    like( exception { $obj->get_modules() }, qr{Invalid entry with key 'invalid' in section '\[test\]'}, '... throws an exception if there are multiple invalid entries' );

    #
    note('push w/out pull entry');
    open $fh, '>', "$modules_file";
    _print( $fh, "[test]\n" );
    _print( $fh, "push=http://example.net/test.git\n" );
    close $fh;

    like( exception { $obj->get_modules() }, qr{Pull url not defined in section '\[test\]'}, '... throws an exception if there is no pull url' );

    # section w/out entries
    open $fh, '>', "$modules_file";
    _print( $fh, "[test]\n" );
    close $fh;

    like( exception { $obj->get_modules() }, qr{Pull url not defined in section '\[test\]'}, '... throws an exception if there is no pull url' );

    #
    note('one module');
    open $fh, '>', "$modules_file";
    _print( $fh, "[test]\n" );
    _print( $fh, "pull=http://example.net/test.git\n" );
    close $fh;

    @modules = $obj->get_modules();
    is( @modules, 1, '... returns a list of one object' );
    isa_ok( $modules[0], 'App::Dotfiles::Module' );
    is( $modules[0]->name, 'test', '... has the correct name' );

    #
    note('two module');
    open $fh, '>', "$modules_file";
    _print( $fh, "[test]\n" );
    _print( $fh, "pull=http://example.net/test.git\n" );
    _print( $fh, "[test2]\n" );
    _print( $fh, "pull=http://example.net/test2.git\n" );
    close $fh;

    @modules = $obj->get_modules();
    is( @modules, 2, '... returns a list of two object' );
    isa_ok( $modules[0], 'App::Dotfiles::Module' );
    isa_ok( $modules[1], 'App::Dotfiles::Module' );
    is( $modules[0]->name,         'test',                         '... the first has the correct name' );
    is( $modules[1]->name,         'test2',                        '... the second has the correct name' );
    is( $modules[0]->pull_url,     'http://example.net/test.git',  '... the first has the correct pull url' );
    is( $modules[0]->push_url,     undef,                          '... undef push url' );
    is( $modules[1]->pull_url,     'http://example.net/test2.git', '... the second has the correct pull url' );
    is( $modules[1]->push_url,     undef,                          '... undef push url' );
    is( $modules[0]->source_shift, q{.},                           '... the first has the correct default source_shift' );
    isa_ok( $modules[0]->source_shift, 'Path::Tiny' );
    is( $modules[0]->target_shift, q{.}, '... default target_shift' );
    isa_ok( $modules[0]->target_shift, 'Path::Tiny' );
    is( $modules[1]->source_shift, q{.}, '... the second has the correct default source_shift' );
    isa_ok( $modules[1]->source_shift, 'Path::Tiny' );
    is( $modules[1]->target_shift, q{.}, '... default target_shift' );
    isa_ok( $modules[1]->target_shift, 'Path::Tiny' );

    #
    note('four modules with source_shift/target_shift');
    open $fh, '>', "$modules_file";
    _print( $fh, "[test1]\n" );
    _print( $fh, "pull=http://example.net/test1.git\n" );
    _print( $fh, "[test2]\n" );
    _print( $fh, "pull=http://example.net/test2.git\n" );
    _print( $fh, "source_shift=a/b c/d\n" );
    _print( $fh, "[test3]\n" );
    _print( $fh, "pull=http://example.net/test3.git\n" );
    _print( $fh, "target_shift=x/y/z\n" );
    _print( $fh, "[test4]\n" );
    _print( $fh, "pull=http://example.net/test4.git\n" );
    _print( $fh, "source_shift=A\n" );
    _print( $fh, "target_shift=B\n" );
    close $fh;

    @modules = $obj->get_modules();
    is( @modules, 4, '... returns a list of four object' );
    isa_ok( $modules[0], 'App::Dotfiles::Module' );
    isa_ok( $modules[1], 'App::Dotfiles::Module' );
    isa_ok( $modules[2], 'App::Dotfiles::Module' );
    isa_ok( $modules[3], 'App::Dotfiles::Module' );
    is( $modules[0]->name,         'test1',                        '... the first has the correct name' );
    is( $modules[1]->name,         'test2',                        '... the second has the correct name' );
    is( $modules[2]->name,         'test3',                        '... the third has the correct name' );
    is( $modules[3]->name,         'test4',                        '... the fourth has the correct name' );
    is( $modules[0]->pull_url,     'http://example.net/test1.git', '... the first has the correct pull url' );
    is( $modules[0]->push_url,     undef,                          '... undef push url' );
    is( $modules[1]->pull_url,     'http://example.net/test2.git', '... the second has the correct pull url' );
    is( $modules[1]->push_url,     undef,                          '... undef push url' );
    is( $modules[2]->pull_url,     'http://example.net/test3.git', '... the third has the correct pull url' );
    is( $modules[2]->push_url,     undef,                          '... undef push url' );
    is( $modules[3]->pull_url,     'http://example.net/test4.git', '... the fourth has the correct pull url' );
    is( $modules[3]->push_url,     undef,                          '... undef push url' );
    is( $modules[0]->source_shift, q{.},                           '... the first has the correct default source_shift' );
    isa_ok( $modules[0]->source_shift, 'Path::Tiny' );
    is( $modules[0]->target_shift, q{.}, '... default target_shift' );
    isa_ok( $modules[0]->target_shift, 'Path::Tiny' );
    is( $modules[1]->source_shift, path('a/b c/d'), '... the second has the correct source_shift' );
    isa_ok( $modules[1]->source_shift, 'Path::Tiny' );
    is( $modules[1]->target_shift, q{.}, '... default target_shift' );
    isa_ok( $modules[1]->target_shift, 'Path::Tiny' );
    is( $modules[2]->source_shift, q{.}, '... the third has the correct default source_shift' );
    isa_ok( $modules[2]->source_shift, 'Path::Tiny' );
    is( $modules[2]->target_shift, path('x/y/z'), '... target_shift' );
    isa_ok( $modules[2]->target_shift, 'Path::Tiny' );
    is( $modules[3]->source_shift, 'A', '... the fourth has the correct source_shift' );
    isa_ok( $modules[3]->source_shift, 'Path::Tiny' );
    is( $modules[3]->target_shift, 'B', '... target_shift' );
    isa_ok( $modules[3]->target_shift, 'Path::Tiny' );

    #
    note('two modules w/ push url');
    open $fh, '>', "$modules_file";
    _print( $fh, "[test]\n" );
    _print( $fh, "pull=http://example.net/test.git\n" );
    _print( $fh, "push=http://example.net/test3.git\n" );
    _print( $fh, "[test2]\n" );
    _print( $fh, "pull=http://example.net/test2.git\n" );
    _print( $fh, "push=http://example.net/test4.git\n" );
    close $fh;

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

# vim: ts=4 sts=4 sw=4 et: syntax=perl
