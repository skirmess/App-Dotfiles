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

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Dotfiles::Error

=head1 VERSION

Version 0.001

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/App-Dotfiles/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/App-Dotfiles>

  git clone https://github.com/skirmess/App-Dotfiles.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2019 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
