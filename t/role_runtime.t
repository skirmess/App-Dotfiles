#!perl

use 5.006;
use strict;
use warnings;

use Test::Fatal qw(dies_ok exception);
use Test::More;

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

# vim: ts=4 sts=4 sw=4 et: syntax=perl
