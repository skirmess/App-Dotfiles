package App::Dotfiles::Runtime;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use File::Spec;
use Git::Wrapper;

use App::Dotfiles::Error;

use Moo;
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
    my $self = shift;

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
    my $self = shift;

    my $home = $self->home_path;

    return File::Spec->catfile( $home, '.files' );
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
