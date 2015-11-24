requires "Benchmark" => "0";
requires "Carp" => "0";
requires "Class::MOP" => "0";
requires "File::Find" => "0";
requires "File::Spec" => "0";
requires "List::MoreUtils" => "0";
requires "List::Util" => "0";
requires "Moose" => "2.0000";
requires "Moose::Role" => "2.0000";
requires "Moose::Util::TypeConstraints" => "0";
requires "Package::DeprecationManager" => "0";
requires "Parallel::ForkManager" => "0";
requires "Sub::Attribute" => "0";
requires "TAP::Formatter::Color" => "0";
requires "TAP::Stream" => "0.44";
requires "Test::Builder" => "0";
requires "Test::Most" => "0.32";
requires "Try::Tiny" => "0";
requires "namespace::autoclean" => "0";
requires "perl" => "v5.10.0";
requires "strict" => "0";
requires "warnings" => "0";
recommends "Parallel::ForkManager" => "v0.7.6";

on 'test' => sub {
  requires "Carp::Always" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "Scalar::Util" => "0";
  requires "Test::More" => "0.96";
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
  requires "Code::TidyAll" => "0.24";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Perl::Critic" => "1.123";
  requires "Perl::Tidy" => "20140711";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::Code::TidyAll" => "0.24";
  requires "Test::EOL" => "0";
  requires "Test::Mojibake" => "0";
  requires "Test::More" => "0.88";
  requires "Test::NoTabs" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Pod::LinkCheck" => "0";
  requires "Test::Pod::No404s" => "0";
  requires "Test::Spelling" => "0.12";
  requires "Test::Synopsis" => "0";
  requires "Test::Version" => "1";
};
