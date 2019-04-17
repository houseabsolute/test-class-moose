requires "Benchmark" => "0";
requires "Carp" => "0";
requires "Class::MOP" => "0";
requires "Exporter" => "0";
requires "File::Find" => "0";
requires "File::Spec" => "0";
requires "Import::Into" => "0";
requires "JSON::MaybeXS" => "0";
requires "List::SomeUtils" => "0";
requires "List::Util" => "0";
requires "Module::Runtime" => "0";
requires "Module::Util" => "0";
requires "Moose" => "2.0000";
requires "Moose::Role" => "2.0000";
requires "Moose::Util" => "0";
requires "Moose::Util::TypeConstraints" => "0";
requires "MooseX::Getopt" => "0.71";
requires "MooseX::Getopt::Dashes" => "0";
requires "Package::DeprecationManager" => "0.16";
requires "Parallel::ForkManager" => "0";
requires "Scalar::Util" => "0";
requires "Sub::Attribute" => "0";
requires "TAP::Formatter::Color" => "3.29";
requires "Test2" => "1.302118";
requires "Test2::API" => "0";
requires "Test2::AsyncSubtest" => "0.000018";
requires "Test2::IPC" => "0";
requires "Test2::Tools::AsyncSubtest" => "0";
requires "Test::Most" => "0";
requires "Try::Tiny" => "0";
requires "namespace::autoclean" => "0";
requires "perl" => "5.010000";
requires "strict" => "0";
requires "warnings" => "0";
recommends "Parallel::ForkManager" => "v0.7.6";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "File::Temp" => "0";
  requires "Test2::Tools::Basic" => "0";
  requires "Test2::Tools::Class" => "0";
  requires "Test2::Tools::Compare" => "0";
  requires "Test2::Tools::Subtest" => "0";
  requires "Test2::V0" => "0";
  requires "Test::Builder" => "0";
  requires "Test::More" => "1.302015";
  requires "Test::Requires" => "0";
  requires "Test::Warnings" => "0";
  requires "lib" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
  recommends "Test::Output" => "0.0005";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Code::TidyAll" => "0.56";
  requires "Code::TidyAll::Plugin::SortLines::Naturally" => "0.000003";
  requires "Code::TidyAll::Plugin::Test::Vars" => "0.02";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Parallel::ForkManager" => "1.19";
  requires "Perl::Critic" => "1.126";
  requires "Perl::Tidy" => "20160302";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Pod::Wordlist" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::CPAN::Meta::JSON" => "0.16";
  requires "Test::CleanNamespaces" => "0.15";
  requires "Test::Code::TidyAll" => "0.50";
  requires "Test::EOL" => "0";
  requires "Test::Mojibake" => "0";
  requires "Test::More" => "0.96";
  requires "Test::NoTabs" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Portability::Files" => "0";
  requires "Test::Spelling" => "0.12";
  requires "Test::Vars" => "0.009";
  requires "Test::Version" => "2.05";
};
