package App::Dotfiles::Role::Repository;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Moo::Role;

use App::Dotfiles::Error;

use File::Spec;
use Git::Wrapper;
use Try::Tiny;

use namespace::clean;

requires 'name';
requires '_verify_remotes_before_update';

has git => (
    is       => 'lazy',
    init_arg => undef,
);

has module_path => (
    is       => 'lazy',
    init_arg => undef,
);

has pull_url => (
    is => 'ro',
);

has push_url => (
    is => 'ro',
);

sub clone_repository {
    my ($self) = @_;

    my $pull_url    = $self->pull_url;
    my $push_url    = $self->push_url;
    my $module_path = $self->module_path;

    App::Dotfiles::Error->throw(q{Cannot clone repository without a 'pull_url'})
      if !defined $pull_url;
    App::Dotfiles::Error->throw("Directory '$module_path' already exists")
      if -d $module_path;

    my $git = $self->git;
    $git->clone( $pull_url, $module_path );

    if ( defined $push_url ) {
        $git->remote( 'set-url', '--push', 'origin', $push_url );
    }

    return;
}

sub does_repository_exist {
    my ($self) = @_;

    my $module_path = $self->module_path;

    return if !-d "$module_path/.git";

    my $git = $self->git;

    try {
        $git->RUN( 'rev-parse', '--resolve-git-dir', File::Spec->catfile( $module_path, '.git' ) );
    }
    catch {
        App::Dotfiles::Error->throw("Directory '$module_path' exists but is not a valid Git directory");
    };

    return 1;
}

sub get_repository_status {
    my ($self) = @_;

    my $module_path = $self->module_path;
    my $git         = $self->git;

    my @result;

  LINE:
    for my $line ( $git->RUN( 'status', '-s' ) ) {
        if ( my ($status) = $line =~ m{ ^ (..) \s (.*) }xsm ) {
            push @result, [ $status, "$module_path/$2" ];
            next LINE;
        }

        App::Dotfiles::Error->throw("internal error: invalid output from 'git status -s': $line");
    }

    return @result;
}

sub update_repository {
    my ($self) = @_;

    my $git = $self->git;

    App::Dotfiles::Error::E_REPOSITORY_IS_DIRTY->throw('Repository is dirty')
      if scalar $git->RUN( 'status', '-s' ) != 0;

    $git->pull('--ff-only');

    return;
}

sub verify_remote {
    my ($self) = @_;

    my $pull_url = $self->pull_url;
    App::Dotfiles::Error->throw(q{'pull_url' not defined})
      if !defined $pull_url;

    my $name        = $self->name;
    my $module_path = $self->module_path;
    App::Dotfiles::Error->throw("Module '$name' does not exist")
      if !-d $module_path;

    my $push_url = $self->push_url;
    if ( !defined $push_url ) {
        $push_url = $pull_url;
    }

    my $git = $self->git;

    $git->remote( 'show', 'origin', '-n' );

    my $pull_url_configured;
    my $push_url_configured;
  LINE:
    foreach my $line ( @{ $git->OUT } ) {
        if ( $line =~ m{ ^ \s* Fetch \s+ URL: \s* (.*) }xsm ) {
            App::Dotfiles::Error->throw(q{I do not understand the output from 'git remote show origin -n'})
              if defined $pull_url_configured;

            $pull_url_configured = $1;
            next LINE;
        }

        if ( $line =~ m{ ^ \s* Push \s+ URL: \s* (.*) }xsm ) {
            App::Dotfiles::Error->throw(q{I do not understand the output from 'git remote show origin -n'})
              if defined $push_url_configured;

            $push_url_configured = $1;
            next LINE;
        }
    }

    App::Dotfiles::Error->throw("Pull url of remote 'origin' of module '$name' is not configured but should be '$pull_url'")
      if $pull_url_configured eq 'origin';

    App::Dotfiles::Error->throw("Pull url of remote 'origin' of module '$name' is '$pull_url_configured' but should be '$pull_url'")
      if $pull_url_configured ne $pull_url;

    App::Dotfiles::Error->throw("Push url of remote 'origin' of module '$name' is '$push_url_configured' but should be '$push_url'")
      if $push_url_configured ne $push_url;

    return;
}

sub _build_git {
    my ($self) = @_;

    my $module_path = $self->module_path;
    my $git         = Git::Wrapper->new($module_path);

    return $git;
}

sub _build_module_path {
    my ($self) = @_;

    my $runtime       = $self->runtime;
    my $dotfiles_path = $runtime->dotfiles_path;
    my $name          = $self->name;

    return "$dotfiles_path/$name";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Dotfiles::Role::Repository

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
