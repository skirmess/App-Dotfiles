package Boradis;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Moo;
has name => (
    is => 'ro',
);
has _verify_remotes_before_update => (
    is => 'ro',
);
with 'App::Dotfiles::Role::Repository';

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
