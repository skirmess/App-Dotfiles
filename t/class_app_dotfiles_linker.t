#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::Fatal qw(dies_ok exception);
use Test::More;
use Test::TempDir::Tiny;

use App::Dotfiles::Runtime;
use App::Dotfiles::Linker;

main();

sub main {
    my $class = 'App::Dotfiles::Linker';

    like( exception { $class->new() }, "/ \QMissing required arguments: runtime\E /xsm", q{'runtime' is required with 'new()'} );

    my $home = tempdir();
    my $runtime = new_ok( 'App::Dotfiles::Runtime', [ home_path => $home ] );

    #
    note('defaults');
    my $obj = new_ok( $class, [ runtime => $runtime ] );

    isa_ok( $obj->runtime, 'App::Dotfiles::Runtime', q{attribute 'runtime'} );
    is( ref $obj->_dirs, ref {}, q{attribute '_dirs'} );
    dies_ok { $obj->_dirs('abc') } '... is a read-only accessor';
    is( ref $obj->_links, ref {}, q{attribute '_links'} );
    dies_ok { $obj->_links('abc') } '... is a read-only accessor';

    #
    note('non-defaults');
    $obj = new_ok( $class, [ runtime => $runtime, _dirs => 1, _links => 1 ] );

    isa_ok( $obj->runtime, 'App::Dotfiles::Runtime', q{attribute 'runtime'} );
    is( ref $obj->_dirs,  ref {}, q{attribute '_dirs'} );
    is( ref $obj->_links, ref {}, q{attribute '_links'} );

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
