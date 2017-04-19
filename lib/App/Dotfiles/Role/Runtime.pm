package App::Dotfiles::Role::Runtime;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Moo::Role;

use namespace::clean;

has runtime => (
    is       => 'ro',
    required => 1,
);

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
