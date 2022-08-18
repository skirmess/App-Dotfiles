use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    ABSTRACT           => 'dotfiles manager',
    AUTHOR             => 'Sven Kirmess <sven.kirmess@kzone.ch>',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    DISTNAME  => 'App-Dotfiles',
    EXE_FILES => [
        'bin/dotf',
    ],
    LICENSE          => 'open_source',
    MIN_PERL_VERSION => '5.006',
    NAME             => 'App::Dotfiles',
    PREREQ_PM        => {
        Carp                  => 0,
        'Config::Std'         => 0,
        'File::Copy'          => 0,
        'File::HomeDir::Tiny' => 0,
        'File::Spec'          => 0,
        'Getopt::Long'        => 0,
        'Git::Wrapper'        => 0,
        Moo                   => 0,
        'Moo::Role'           => 0,
        'Path::Tiny'          => 0,
        'Pod::Usage'          => '1.69',
        'Safe::Isa'           => 0,
        'Try::Tiny'           => 0,
        'custom::failures'    => 0,
        'namespace::clean'    => 0,
        strict                => 0,
        warnings              => 0,
    },
    TEST_REQUIRES => {
        'Capture::Tiny'         => 0,
        Cwd                     => 0,
        English                 => 0,
        Exporter                => 0,
        'File::Basename'        => 0,
        'File::Path'            => '2.07',
        'File::Spec::Functions' => 0,
        'Test::Fatal'           => 0,
        'Test::More'            => '0.88',
        'Test::Script'          => '1.09',
        lib                     => 0,
    },
    VERSION => '0.001',
    test    => {
        TESTS => 't/*.t',
    },
);

my %FallbackPrereqs = (
    'Capture::Tiny'         => 0,
    Carp                    => 0,
    'Config::Std'           => 0,
    Cwd                     => 0,
    English                 => 0,
    Exporter                => 0,
    'File::Basename'        => 0,
    'File::Copy'            => 0,
    'File::HomeDir::Tiny'   => 0,
    'File::Path'            => '2.07',
    'File::Spec'            => 0,
    'File::Spec::Functions' => 0,
    'Getopt::Long'          => 0,
    'Git::Wrapper'          => 0,
    Moo                     => 0,
    'Moo::Role'             => 0,
    'Path::Tiny'            => 0,
    'Pod::Usage'            => '1.69',
    'Safe::Isa'             => 0,
    'Test::Fatal'           => 0,
    'Test::More'            => '0.88',
    'Test::Script'          => '1.09',
    'Try::Tiny'             => 0,
    'custom::failures'      => 0,
    lib                     => 0,
    'namespace::clean'      => 0,
    strict                  => 0,
    warnings                => 0,
);

if ( !eval { ExtUtils::MakeMaker->VERSION('6.63_03') } ) {
    delete $WriteMakefileArgs{TEST_REQUIRES};
    delete $WriteMakefileArgs{BUILD_REQUIRES};
    $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

if ( !eval { ExtUtils::MakeMaker->VERSION(6.52) } ) {
    delete $WriteMakefileArgs{CONFIGURE_REQUIRES};
}

WriteMakefile(%WriteMakefileArgs);

# vim: ts=4 sts=4 sw=4 et: syntax=perl
