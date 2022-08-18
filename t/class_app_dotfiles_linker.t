#!perl

# vim: ts=4 sts=4 sw=4 et: syntax=perl
#
# Copyright (c) 2017-2022 Sven Kirmess
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use 5.006;
use strict;
use warnings;

use Test::Fatal qw(dies_ok exception);
use Test::More 0.88;

use Cwd            ();
use File::Basename ();
use File::Spec     ();
use lib File::Spec->catdir( File::Basename::dirname( Cwd::abs_path __FILE__ ), 'lib' );

use Local::Test::TempDir qw(tempdir);

use App::Dotfiles::Runtime;
use App::Dotfiles::Linker;

main();

sub main {
    my $class = 'App::Dotfiles::Linker';

    like( exception { $class->new() }, "/ \QMissing required arguments: runtime\E /xsm", q{'runtime' is required with 'new()'} );

    my $home    = tempdir();
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
