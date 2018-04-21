package App::Dotfiles::Runtime;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Moo;

use App::Dotfiles::Error;

use File::Spec;
use Git::Wrapper;

use namespace::clean;

has config_dir => (
    is      => 'ro',
    default => '.config',
);

has dotfiles_path => (
    is => 'lazy',
);

has home_path => (
    is       => 'ro',
    required => 1,
);

has modules_config_file => (
    is      => 'ro',
    default => 'modules.ini',
);

sub BUILD {
    my ($self) = @_;

    my $home = $self->home_path;

    App::Dotfiles::Error->throw('Home directory is not specified')
      if !defined $home;
    App::Dotfiles::Error->throw('Home directory is not specified')
      if $home eq q{};
    App::Dotfiles::Error->throw("Home directory '$home' does not exist")
      if !-e $home;
    App::Dotfiles::Error->throw("Home directory '$home' is not a directory")
      if !-d $home;

    App::Dotfiles::Error->throw('No Git in PATH')
      if !Git::Wrapper->has_git_in_path();

    return;
}

sub _build_dotfiles_path {
    my ($self) = @_;

    my $home = $self->home_path;

    return File::Spec->catfile( $home, '.files' );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Dotfiles::Runtime

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

This software is Copyright (c) 2017-2018 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
