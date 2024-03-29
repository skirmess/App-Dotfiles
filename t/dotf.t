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

use Test::More 0.88;
use Test::Script 1.09;

use Cwd            ();
use File::Basename ();
use File::Spec     ();
use lib File::Spec->catdir( File::Basename::dirname( Cwd::abs_path __FILE__ ), 'lib' );

use Local::Test::TempDir qw(tempdir);

main();

sub main {
    my $home = tempdir();

    script_compiles('bin/dotf');

    script_runs( [ 'bin/dotf', '--no-such-option' ], { exit => 2, }, 'Return code 2 for an invalid option' );

    script_runs( [ 'bin/dotf', '-h', $home, 'update' ], { exit => 1, }, 'Return code 1 if we try to update without being initialized' );
    script_stderr_is("dotf is not initialized. Please run 'dotf init' first\n");

    done_testing();

    exit 0;
}
