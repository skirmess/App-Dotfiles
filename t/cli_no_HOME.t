#!perl
use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::More;
use Test::TempDir::Tiny;

use App::Dotfiles::CLI;

BEGIN {
    $ENV{HOME} = q{};
}

use English qw(-no_match_vars);

## no critic (RegularExpressions::RequireDotMatchAnything)
## no critic (RegularExpressions::RequireExtendedFormatting)
## no critic (RegularExpressions::RequireLineBoundaryMatching)
## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
## no critic (NamingConventions::Capitalization)

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
        like( $exception, qr{Cannot find home directory[.] Is the HOME environment variable set?}, '... with the correct message' );
        is_deeply( \@ARGV, [], '... @ARGV is empty' );
    }

    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
