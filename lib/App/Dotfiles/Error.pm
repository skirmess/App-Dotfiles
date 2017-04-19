package App::Dotfiles::Error;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use custom::failures qw(E_NO_CONFIG_REPOSITORY E_REPOSITORY_IS_DIRTY E_USAGE);

sub message {
    my ( $self, $msg ) = @_;

    return $msg;
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
