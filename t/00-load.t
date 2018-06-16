#!perl

use 5.006;
use strict;
use warnings;

# Automatically generated file; DO NOT EDIT.

use Test::More 0.88;

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
