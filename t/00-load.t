#!perl -T
use 5.006;
use strict;
use warnings;

use Test::More;

my @modules = (
    'App::Dotfiles',
    'App::Dotfiles::CLI',
    'App::Dotfiles::CLI::Command',
    'App::Dotfiles::Error',
    'App::Dotfiles::Module',
    'App::Dotfiles::Module::Config',
    'App::Dotfiles::Role::Repository',
    'App::Dotfiles::Role::Runtime',
    'App::Dotfiles::Runtime',
);

plan tests => scalar @modules;

for my $module (@modules) {
    require_ok($module) || BAIL_OUT();
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
