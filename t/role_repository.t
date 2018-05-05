#!perl

use 5.006;
use strict;
use warnings;

use Test::Fatal;
use Test::More;

use lib 't/lib';

use Boradis;

main();

sub main {

    like( exception { require Aschelan }, "/ \QCan't apply App::Dotfiles::Role::Repository to Aschelan - missing name, _verify_remotes_before_update at\E /xsm", q{Role 'App::Dotfiles::Role::Repository' requires 'name'} );

    new_ok('Boradis');

    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
