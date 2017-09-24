#!perl

use 5.006;
use strict;
use warnings;

# this test was generated with
# Dist::Zilla::Plugin::Author::SKIRMESS::RepositoryBase 0.024

use Test::More;

use lib qw(lib .);

my @modules = qw(
  App::Dotfiles
  App::Dotfiles::CLI
  App::Dotfiles::CLI::Command
  App::Dotfiles::Error
  App::Dotfiles::Linker
  App::Dotfiles::Module
  App::Dotfiles::Module::Config
  App::Dotfiles::Role::Repository
  App::Dotfiles::Role::Runtime
  App::Dotfiles::Runtime
  bin/dotf
);

plan tests => scalar @modules;

for my $module (@modules) {
    require_ok($module) || BAIL_OUT();
}
