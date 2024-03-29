# vim: ts=4 sts=4 sw=4 et: syntax=perl
#
# Copyright (c) 2017-2022 Sven Kirmess
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use 5.006;
use strict;
use warnings;

package App::Dotfiles::CLI;

our $VERSION = '0.001';

use Moo;

use App::Dotfiles::CLI::Command;
use App::Dotfiles::Error;
use App::Dotfiles::Runtime;

use File::HomeDir::Tiny ();
use Getopt::Long;

use namespace::clean;

has runtime => (
    is => 'rw',
);

sub main {
    my ($self) = @_;

    my ( $opt_ref, $command ) = $self->_get_main_options_and_command();

    my $home = $opt_ref->{h};
    if ( !defined $home ) {
        $home = File::HomeDir::Tiny::home();

        App::Dotfiles::Error->throw('Cannot find home directory. Is the HOME environment variable set?')
          if !defined $home || $home eq q{};
    }

    $self->runtime( App::Dotfiles::Runtime->new( home_path => $home ) );

    return $self->_cmd_help()    if $command eq 'help';
    return $self->_cmd_init()    if $command eq 'init';
    return $self->_cmd_status()  if $command eq 'status';
    return $self->_cmd_update()  if $command eq 'update';
    return $self->_cmd_version() if $command eq 'version';

    App::Dotfiles::Error::E_USAGE->throw("unrecognized command '$command'");

    return;
}

sub _get_main_options_and_command {
    my ($self) = @_;

    my $command;
    my %opt;
    GetOptions(
        \%opt,
        'h=s',

        '<>' => sub {
            ($command) = @_;
            die '!FINISH';    ## no critic (ErrorHandling::RequireCarping)
        },
    ) or App::Dotfiles::Error::E_USAGE->throw('usage error in global option section');

    App::Dotfiles::Error::E_USAGE->throw('no command given')
      if !defined $command;

    return \%opt, $command;
}

sub _cmd_help {
    my ($self) = @_;

    App::Dotfiles::Error::E_USAGE->throw('usage error in command option section')
      if @ARGV > 0;

    my $runtime = $self->runtime;

    return App::Dotfiles::CLI::Command->new( runtime => $runtime )->run_help();
}

sub _cmd_init {
    my ($self) = @_;

    App::Dotfiles::Error::E_USAGE->throw('usage error in command option section')
      if @ARGV != 1;

    my $url = shift @ARGV;

    my $runtime = $self->runtime;

    return App::Dotfiles::CLI::Command->new( runtime => $runtime )->run_init($url);
}

sub _cmd_status {
    my ($self) = @_;

    App::Dotfiles::Error::E_USAGE->throw('usage error in command option section')
      if @ARGV > 0;

    my $runtime = $self->runtime;

    return App::Dotfiles::CLI::Command->new( runtime => $runtime )->run_status();
}

sub _cmd_update {
    my ($self) = @_;

    App::Dotfiles::Error::E_USAGE->throw('usage error in command option section')
      if @ARGV > 0;

    my $runtime = $self->runtime;

    return App::Dotfiles::CLI::Command->new( runtime => $runtime )->run_update();
}

sub _cmd_version {
    my ($self) = @_;

    App::Dotfiles::Error::E_USAGE->throw('usage error in command option section')
      if @ARGV > 0;

    print "dotf version $VERSION\n";

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Dotfiles::CLI

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

=cut
