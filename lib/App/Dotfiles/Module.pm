package App::Dotfiles::Module;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Moo;
has name => (
    is       => 'ro',
    required => 1,
);
has _verify_remotes_before_update => (
    is       => 'ro',
    default  => 1,
    init_arg => undef,
);
with 'App::Dotfiles::Role::Runtime', 'App::Dotfiles::Role::Repository';

use namespace::clean;

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
