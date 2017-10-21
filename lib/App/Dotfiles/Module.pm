package App::Dotfiles::Module;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Moo;

use App::Dotfiles::Error;
use Path::Tiny;

has name => (
    is       => 'ro',
    required => 1,
);

has source_path_prefix => (
    is      => 'ro',
    default => sub { path(q{.}) },
);

has target_path_prefix => (
    is      => 'ro',
    default => sub { path(q{.}) },
);

has _verify_remotes_before_update => (
    is       => 'ro',
    default  => 1,
    init_arg => undef,
);

with 'App::Dotfiles::Role::Runtime', 'App::Dotfiles::Role::Repository';

use namespace::clean;

sub get_linkables {
    my ( $self, $path ) = @_;

    $path = path($path);
    my $module_path        = $self->module_path;
    my $source_path_prefix = $self->source_path_prefix;

    my $path_to_process = path($module_path)->child( $source_path_prefix, $path );

    App::Dotfiles::Error->throw("Not a directory: $path_to_process") if -l $path_to_process || !-d $path_to_process;

    my $fh;
    opendir $fh, $path_to_process or App::Dotfiles::Error->throw("Unable to read directory '$path_to_process': $!");
    my @result = map { $path->child($_) } grep { $_ ne q{.} && $_ ne q{..} && $_ ne '.git' } readdir $fh;
    closedir $fh or App::Dotfiles::Error->throw("Unable to read directory '$path_to_process': $!");

    return \@result;
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
