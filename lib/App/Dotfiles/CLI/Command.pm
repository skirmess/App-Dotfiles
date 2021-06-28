package App::Dotfiles::CLI::Command;

use 5.006;
use strict;
use warnings;

our $VERSION = 0.001;

use Pod::Usage 1.69;
use Safe::Isa;
use Try::Tiny;

use App::Dotfiles::Error;
use App::Dotfiles::Linker;
use App::Dotfiles::Module::Config;

use Moo;
with 'App::Dotfiles::Role::Runtime';
use namespace::clean;

sub run_help {
    my ($self) = @_;

    pod2usage(
        {
            -exitval => 'NOEXIT',
            -verbose => 2,          # 1 = SYNOPSIS + OPTIONS + ARGUMENTS + OPTIONS AND ARGUMENTS
                                    # 0 = SYNOPSIS
                                    # 2 = all
                                    # 99 = use sections argument
        },
    );

    return;
}

sub run_init {
    my ( $self, $config_repo_url ) = @_;

    my $runtime = $self->runtime;

    my $config = App::Dotfiles::Module::Config->new( runtime => $runtime, pull_url => $config_repo_url );
    my $name   = $config->name;

    App::Dotfiles::Error->throw("Config '$name' exists already")
      if $config->does_repository_exist();

    print "Initializing config '$name'\n";

    $config->clone_repository();

    return $self->_update_modules();
}

sub run_status {
    my ($self) = @_;

    my $runtime = $self->runtime;
    my $config  = App::Dotfiles::Module::Config->new( runtime => $runtime );

    App::Dotfiles::Error::E_NO_CONFIG_REPOSITORY->throw('config repository does not exist')
      if !$config->does_repository_exist();

    my %modules_config = map { $_->name => $_ } $config->get_modules();

    my $dotfiles_path = $runtime->dotfiles_path;

    my $fh;
    opendir $fh, $dotfiles_path or App::Dotfiles::Error::E_NO_CONFIG_REPOSITORY->throw("cannot read directory '$dotfiles_path': $!");
    my %modules = map { $_ => 1 }
      grep { $_ ne q{.} && $_ ne q{..} && !-l "$dotfiles_path/$_" && -d _ } readdir $fh;
    closedir $fh or App::Dotfiles::Error::E_NO_CONFIG_REPOSITORY->throw("cannot read directory '$dotfiles_path': $!");

    @modules{ keys %modules_config } = values %modules_config;
    $modules{ $config->name() } = $config;

  MODULE:
    for my $name ( sort keys %modules ) {
        my $module = $modules{$name};

        if ( !$module->$_DOES('App::Dotfiles::Role::Repository') ) {
            print " + $dotfiles_path/$name\n";
            next MODULE;
        }

        try {
            if ( $module->does_repository_exist() ) {
                for my $changes_ref ( $module->get_repository_status() ) {
                    print "$changes_ref->[0] $changes_ref->[1]\n";
                }
            }
            elsif ( -e "$dotfiles_path/$name" ) {

                # directory exists but is not a git repository
                print " ~ $dotfiles_path/$name\n";
            }
            else {
                # directory does not exist
                print " - $dotfiles_path/$name\n";
            }
        }
        catch {
            print "$_\n";
        };
    }

    return;
}

sub run_update {
    my ($self) = @_;

    my $runtime = $self->runtime;
    my $config  = App::Dotfiles::Module::Config->new( runtime => $runtime );

    App::Dotfiles::Error::E_NO_CONFIG_REPOSITORY->throw()
      if !$config->does_repository_exist();

    my $name = $config->name;
    print "Updating config '$name'\n";

    $config->update_repository();

    return $self->_update_modules();
}

sub _update_modules {
    my ($self) = @_;

    my $runtime = $self->runtime;
    my $config  = App::Dotfiles::Module::Config->new( runtime => $runtime );

    my @modules = $config->get_modules();

    if ( @modules == 0 ) {
        my $modules_config_file = $runtime->modules_config_file;
        print "No modules configured in '$modules_config_file'\n";
        return;
    }

    my $linker = App::Dotfiles::Linker->new( runtime => $runtime );

    for my $module (@modules) {
        try {
            my $module_name = $module->name();

            if ( $module->does_repository_exist() ) {
                print "Verifying 'remotes' config of module '$module_name'\n";
                $module->verify_remote();

                print "Updating module '$module_name'\n";
                $module->update_repository();
            }
            else {
                my $pull_url    = $module->pull_url;
                my $module_path = $module->module_path;
                print "Cloning repository '$pull_url' into '$module_path'\n";
                $module->clone_repository();
            }

            $linker->plan_module($module);
        }
        catch {
            print "$_\n";
        };
    }

    $linker->run();

    print "Dotfiles updated successfully\n";

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Dotfiles::CLI::Command

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

This software is Copyright (c) 2017-2021 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
