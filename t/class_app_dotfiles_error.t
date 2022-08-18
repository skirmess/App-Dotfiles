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

use Test::Fatal;
use Test::More 0.88;

use App::Dotfiles::Error;

main();

sub main {

    my $exception = exception { App::Dotfiles::Error->throw('test 1 2 3') };
    isa_ok( $exception, 'App::Dotfiles::Error' );
    is( $exception, "test 1 2 3\n", 'correct error message' );

    $exception = exception { App::Dotfiles::Error->throw(q{}) };
    isa_ok( $exception, 'App::Dotfiles::Error' );
    is( $exception, "\n", 'empty error message' );

    $exception = exception { App::Dotfiles::Error->throw() };
    isa_ok( $exception, 'App::Dotfiles::Error' );
    is( $exception, "\n", 'no error message' );

    $exception = exception { App::Dotfiles::Error::E_NO_CONFIG_REPOSITORY->throw('test 1 2 3') };
    isa_ok( $exception, 'App::Dotfiles::Error::E_NO_CONFIG_REPOSITORY' );
    isa_ok( $exception, 'App::Dotfiles::Error' );
    is( $exception, "test 1 2 3\n", 'correct error message' );

    $exception = exception { App::Dotfiles::Error::E_REPOSITORY_IS_DIRTY->throw('test 1 2 3') };
    isa_ok( $exception, 'App::Dotfiles::Error::E_REPOSITORY_IS_DIRTY' );
    isa_ok( $exception, 'App::Dotfiles::Error' );
    is( $exception, "test 1 2 3\n", 'correct error message' );

    $exception = exception { App::Dotfiles::Error::E_USAGE->throw('test 1 2 3') };
    isa_ok( $exception, 'App::Dotfiles::Error::E_USAGE' );
    isa_ok( $exception, 'App::Dotfiles::Error' );
    is( $exception, "test 1 2 3\n", 'correct error message' );

    #
    done_testing();

    exit 0;
}
