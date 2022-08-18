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

use lib 't/lib';

use Chalna;
use App::Dotfiles::Runtime;

main();

sub main {

    like( exception { Chalna->new() }, "/ \QMissing required arguments: runtime\E /xsm", q{App::Dotfiles::Role::Runtime requires attribute 'runtime'} );

    my $obj = new_ok( 'Chalna', [ runtime => 'x' ] );

    is( $obj->runtime, 'x', q{attribute 'runtime'} );
    dies_ok { $obj->runtime('abc') } q{... is a read-only accessor};

    done_testing();

    exit 0;
}
