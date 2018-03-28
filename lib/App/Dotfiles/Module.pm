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

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Dotfiles::Module

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
