package App::Dotfiles::Module::Config;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Config::Std;

use App::Dotfiles::Module;
use App::Dotfiles::Error;

use Moo;
has name => (
    is       => 'lazy',
    init_arg => undef,
);
has _verify_remotes_before_update => (
    is       => 'ro',
    default  => 0,
    init_arg => undef,
);
with 'App::Dotfiles::Role::Runtime', 'App::Dotfiles::Role::Repository';

has modules_config_file_path => (
    is       => 'lazy',
    init_arg => undef,
);

use Path::Tiny;

use namespace::clean;

sub get_modules {
    my ($self) = @_;

    my $runtime     = $self->runtime;
    my $config_file = $self->modules_config_file_path;

    App::Dotfiles::Error->throw("Missing config file '$config_file'")
      if !-e $config_file;

    read_config( $config_file, my %config );

    my $array_ref = ref [];
    my @modules;
    for my $section ( sort keys %config ) {
        App::Dotfiles::Error->throw("Error in configuration file '$config_file': global section not allowed")
          if $section eq q{};

        my $pull_url;
        my $push_url;
        my $source_path_prefix;
        my $target_path_prefix;

      ENTRY:
        for my $key ( keys %{ $config{$section} } ) {
            my $value = $config{$section}->{$key};

            if ( $key eq 'pull' ) {
                App::Dotfiles::Error->throw("'pull' url defined multiple times in section '[$section]'")
                  if defined $pull_url
                  or ref $value eq $array_ref;

                $pull_url = $value;
                next ENTRY;
            }

            if ( $key eq 'push' ) {
                App::Dotfiles::Error->throw("'push' url defined multiple times in section '[$section]'")
                  if defined $push_url
                  or ref $value eq $array_ref;

                $push_url = $value;
                next ENTRY;
            }

            if ( $key eq 'source path prefix' ) {
                App::Dotfiles::Error->throw("'source path prefix' defined multiple times in section '[$section]'")
                  if defined $source_path_prefix
                  or ref $value eq $array_ref;

                $source_path_prefix = $value;
                next ENTRY;
            }

            if ( $key eq 'target path prefix' ) {
                App::Dotfiles::Error->throw("'target path prefix' defined multiple times in section '[$section]'")
                  if defined $target_path_prefix
                  or ref $value eq $array_ref;

                $target_path_prefix = $value;
                next ENTRY;
            }

            App::Dotfiles::Error->throw("Invalid entry '$key=$value' in section '[$section]'")
              if ref $value eq q{};

            App::Dotfiles::Error->throw("Invalid entry with key '$key' in section '[$section]'");
        }

        App::Dotfiles::Error->throw("Pull url not defined in section '[$section]'")
          if !defined $pull_url;

        my $module_args_ref = {
            runtime  => $runtime,
            name     => $section,
            pull_url => $pull_url,
        };

        if ( defined $push_url ) {
            $module_args_ref->{push_url} = $push_url;
        }

        if ( defined $source_path_prefix ) {
            $module_args_ref->{source_path_prefix} = path($source_path_prefix);
        }

        if ( defined $target_path_prefix ) {
            $module_args_ref->{target_path_prefix} = path($target_path_prefix);
        }

        push @modules, App::Dotfiles::Module->new($module_args_ref);
    }

    return @modules;
}

sub _build_modules_config_file_path {
    my ($self) = @_;

    my $runtime = $self->runtime;

    my $dotfiles_path       = $runtime->dotfiles_path;
    my $config_dir          = $runtime->config_dir;
    my $modules_config_file = $runtime->modules_config_file;

    return File::Spec->catfile( $dotfiles_path, $config_dir, $modules_config_file );
}

sub _build_name {
    my ($self) = @_;

    my $runtime    = $self->runtime;
    my $config_dir = $runtime->config_dir;

    return $config_dir;
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
