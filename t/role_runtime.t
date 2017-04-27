#!perl

use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::More;

use lib 't/lib';

use Chalna;
use App::Dotfiles::Runtime;

## no critic (RegularExpressions::RequireDotMatchAnything)
## no critic (RegularExpressions::RequireExtendedFormatting)
## no critic (RegularExpressions::RequireLineBoundaryMatching)

main();

sub main {

    like( exception { Chalna->new() }, qr{Missing required arguments: runtime}, q{App::Dotfiles::Role::Runtime requires attribute 'runtime'} );

    my $obj = new_ok( 'Chalna', [ runtime => 'x' ] );

    is( $obj->runtime, 'x', q{attribute 'runtime'} );
    like( exception { $obj->runtime('abc') }, qr{runtime is a read-only accessor}, q{... is a read-only accessor} );

    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
