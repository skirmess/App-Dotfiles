#!perl

use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::More;

use lib 't/lib';

use Boradis;

## no critic (RegularExpressions::RequireDotMatchAnything)
## no critic (RegularExpressions::RequireExtendedFormatting)
## no critic (RegularExpressions::RequireLineBoundaryMatching)

main();

sub main {

    like( exception { require Aschelan }, qr{Can't apply App::Dotfiles::Role::Repository to Aschelan - missing name, _verify_remotes_before_update at}, q{Role 'App::Dotfiles::Role::Repository' requires 'name'} );

    my $obj = new_ok('Boradis');

    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
