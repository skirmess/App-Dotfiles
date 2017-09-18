requires "Carp" => "0";
requires "Config::Std" => "0";
requires "File::Copy" => "0";
requires "File::HomeDir" => "0";
requires "File::Spec" => "0";
requires "Getopt::Long" => "0";
requires "Git::Wrapper" => "0";
requires "Moo" => "0";
requires "Moo::Role" => "0";
requires "Path::Tiny" => "0";
requires "Pod::Usage" => "0";
requires "Safe::Isa" => "0";
requires "Try::Tiny" => "0";
requires "custom::failures" => "0";
requires "namespace::clean" => "0";
requires "perl" => "5.006";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Capture::Tiny" => "0";
  requires "English" => "0";
  requires "File::Path" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::More" => "0";
  requires "Test::Script" => "1.09";
  requires "Test::TempDir::Tiny" => "0";
  requires "autodie" => "0";
  requires "lib" => "0";
  requires "perl" => "5.006";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "perl" => "5.006";
};

on 'develop' => sub {
  requires "Perl::Critic" => "1.130";
  requires "Perl::Critic::Policy::Moose::ProhibitDESTROYMethod" => "1.05";
  requires "Perl::Critic::Policy::Moose::ProhibitLazyBuild" => "1.05";
  requires "Perl::Critic::Policy::Moose::ProhibitMultipleWiths" => "1.05";
  requires "Perl::Critic::Policy::Moose::ProhibitNewMethod" => "1.05";
  requires "Perl::Critic::Policy::Moose::RequireCleanNamespace" => "1.05";
  requires "Perl::Critic::Policy::Moose::RequireMakeImmutable" => "1.05";
  requires "Perl::Critic::Utils" => "0";
  requires "Pod::Wordlist" => "0";
  requires "Test::CPAN::Changes" => "0";
  requires "Test::CPAN::Meta" => "0.12";
  requires "Test::CPAN::Meta::JSON" => "0";
  requires "Test::CleanNamespaces" => "0";
  requires "Test::DistManifest" => "1.003";
  requires "Test::EOL" => "0";
  requires "Test::Kwalitee" => "0";
  requires "Test::MinimumVersion" => "0.008";
  requires "Test::Mojibake" => "0";
  requires "Test::More" => "0.88";
  requires "Test::NoTabs" => "0";
  requires "Test::Perl::Critic" => "0";
  requires "Test::Pod" => "1.26";
  requires "Test::Portability::Files" => "0";
  requires "Test::Spelling" => "0.12";
  requires "Test::Version" => "0.04";
};
