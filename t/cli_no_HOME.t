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

use Cwd            ();
use File::Basename ();
use File::Spec     ();
use lib File::Spec->catdir( File::Basename::dirname( Cwd::abs_path __FILE__ ), 'lib' );

use Local::Test::TempDir qw(tempdir);

use App::Dotfiles::CLI;

BEGIN {
    $ENV{HOME} = q{};
}

use English qw(-no_match_vars);

main();

sub _note_ARGV {
    local $LIST_SEPARATOR = q{', '};
    note("\@ARGV = ('@ARGV')");
    return;
}

sub main {
    my $obj = new_ok('App::Dotfiles::CLI');

    #
    {
        local @ARGV = qw(status);
        _note_ARGV();

        my $exception = exception { $obj->main() };
        isa_ok( $exception, 'App::Dotfiles::Error', '... throws an exception if no home is specified and $HOME is not set' );
        like( $exception, "/ \QCannot find home directory. Is the HOME environment variable set?\E /xsm", '... with the correct message' );
        is_deeply( \@ARGV, [], '... @ARGV is empty' );
    }

    done_testing();

    exit 0;
}
