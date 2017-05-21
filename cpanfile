requires "Carp" => "0";
requires "Config::Std" => "0";
requires "File::Copy" => "0";
requires "File::HomeDir" => "0";
requires "File::Spec" => "0";
requires "Getopt::Long" => "0";
requires "Git::Wrapper" => "0";
requires "Log::Any::Adapter" => "0";
requires "Log::Any::Adapter::Screen" => "0";
requires "Moo" => "0";
requires "Moo::Role" => "0";
requires "MooX::Role::Logger" => "0";
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
  requires "English" => "0";
  requires "File::Path" => "0";
  requires "Log::Any" => "0";
  requires "Log::Any::Test" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::More" => "0";
  requires "Test::Script" => "1.09";
  requires "Test::TempDir::Tiny" => "0";
  requires "autodie" => "0";
  requires "lib" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Test::Kwalitee" => "0";
  requires "Test::MinimumVersion" => "0";
  requires "Test::More" => "0";
  requires "Test::Perl::Critic" => "0";
  requires "autodie" => "0";
};
