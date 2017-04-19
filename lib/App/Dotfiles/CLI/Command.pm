package App::Dotfiles::CLI::Command;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Pod::Usage;
use Safe::Isa;
use Stow;
use Try::Tiny;

use App::Dotfiles::Error;
use App::Dotfiles::Module::Config;

use Moo;
with 'MooX::Role::Logger', 'App::Dotfiles::Role::Runtime';
use namespace::clean;

has stow_verbose => (
    is      => 'ro',
    default => 1,
);

sub run_help {
    my $self = shift;

    pod2usage(
        {
            -exitval => 'NOEXIT',
            -verbose => 2,          # 1 = SYNOPSIS + OPTIONS + ARGUMENTS + OPTIONS AND ARGUMENTS
                                    # 0 = SYNOPSIS
                                    # 2 = all
                                    # 99 = use sections argument
        }
    );

    return;
}

sub run_init {
    my $self = shift;
    my ($config_repo_url) = @_;

    my $runtime = $self->runtime;

    my $config = App::Dotfiles::Module::Config->new( runtime => $runtime, pull_url => $config_repo_url );
    my $name = $config->name;

    App::Dotfiles::Error->throw("Config '$name' exists already")
      if $config->does_repository_exist();

    $self->_logger->info("Initializing config '$name'");

    $config->clone_repository();

    return $self->_update_modules();
}

sub run_status {
    my $self = shift;

    my $runtime = $self->runtime;
    my $config = App::Dotfiles::Module::Config->new( runtime => $runtime );

    App::Dotfiles::Error::E_NO_CONFIG_REPOSITORY->throw('config repository does not exist')
      if !$config->does_repository_exist();

    my %modules_config = map { $_->name => $_ } $config->get_modules();

    my $dotfiles_path = $runtime->dotfiles_path;

    my $fh;
    opendir $fh, $dotfiles_path;
    my %modules = map { $_ => 1 }
      grep { $_ ne q{.} && $_ ne q{..} && !-l "$dotfiles_path/$_" && -d _ } readdir $fh;
    closedir $fh;

    @modules{ keys %modules_config } = values %modules_config;
    $modules{ $config->name() } = $config;

  MODULE:
    for my $name ( sort keys %modules ) {
        my $module = $modules{$name};

        if ( !$module->DOES('App::Dotfiles::Role::Repository') ) {
            $self->_logger->error(" + $dotfiles_path/$name");
            next MODULE;
        }

        try {
            if ( $module->does_repository_exist() ) {
                for my $changes_ref ( $module->get_repository_status() ) {
                    $self->_logger->info("$changes_ref->[0] $changes_ref->[1]");
                }
            }
            elsif ( -e "$dotfiles_path/$name" ) {

                # directory exists but is not a git repository
                $self->_logger->error(" ~ $dotfiles_path/$name");
            }
            else {
                # directory does not exist
                $self->_logger->error(" - $dotfiles_path/$name");
            }
        }
        catch {
            $self->_logger->error($_);
        };
    }

    return;
}

sub run_update {
    my $self = shift;

    my $runtime = $self->runtime;
    my $config = App::Dotfiles::Module::Config->new( runtime => $runtime );

    App::Dotfiles::Error::E_NO_CONFIG_REPOSITORY->throw()
      if !$config->does_repository_exist();

    my $name = $config->name;
    $self->_logger->info("Updating config '$name'");

    $config->update_repository();

    return $self->_update_modules();
}

sub _stow {
    my $self = shift;
    my (@packages) = @_;

    if ( @packages == 0 ) {
        $self->_logger->info('There are no packages to stow');
        return;
    }

    my $runtime       = $self->runtime;
    my $home          = $runtime->home_path;
    my $dotfiles_path = $runtime->dotfiles_path;
    my $verbose       = $self->stow_verbose ? 1 : 0;

    $self->_logger->info(q{Planning 'stow' actions});

    my %stow_options = (
        target  => $home,
        dir     => $dotfiles_path,
        verbose => $verbose,
        adopt   => 1,
    );

    my $stow = Stow->new(%stow_options);
    $stow->plan_stow(@packages);

    my %conflicts = $stow->get_conflicts;

    if (%conflicts) {
      ACTION:
        foreach my $action ( 'unstow', 'stow' ) {
            next ACTION if !$conflicts{$action};

            foreach my $package ( sort keys %{ $conflicts{$action} } ) {
                $self->_logger->error("${action}ing '$package' would cause conflicts:");
                foreach my $message ( sort @{ $conflicts{$action}{$package} } ) {
                    $self->_logger->error("  * $message");
                }
            }
        }

        App::Dotfiles::Error->throw('All stow operations aborted');
    }

    $self->_logger->info( 'Stowing modules ' . join q{ }, @packages );
    $stow->process_tasks();

    return;
}

sub _update_modules {
    my $self = shift;

    my $runtime = $self->runtime;
    my $config = App::Dotfiles::Module::Config->new( runtime => $runtime );

    my @modules = $config->get_modules();

    if ( @modules == 0 ) {
        my $modules_config_file = $runtime->modules_config_file;
        $self->_logger->warning("No modules configured in '$modules_config_file'");
        return;
    }

    my @modules_to_stow;
    for my $module (@modules) {
        try {
            my $module_name = $module->name();

            if ( $module->does_repository_exist() ) {
                $self->_logger->info("Verifying 'remotes' config of module '$module_name'");
                $module->verify_remote();

                $self->_logger->info("Updating module '$module_name'");
                $module->update_repository();
            }
            else {
                my $pull_url    = $module->pull_url;
                my $module_path = $module->module_path;
                $self->_logger->info("Cloning repository '$pull_url' into '$module_path'");
                $module->clone_repository();
            }

            push @modules_to_stow, $module_name;
        }
        catch {
            $self->_logger->error($_);
        };
    }

    $self->_stow(@modules_to_stow);

    $self->_logger->info('Dotfiles updated successfully');

    return;
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
