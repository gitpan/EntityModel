
use strict;
use warnings;

BEGIN { require 5.010; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Define and manage entities across languages',
  'AUTHOR' => 'Tom Molesworth <cpan@entitymodel.com>',
  'BUILD_REQUIRES' => {
    'Test::Class' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'EntityModel',
  'EXE_FILES' => [
    'bin/entitymodel',
    'bin/entitymodel'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'EntityModel',
  'PREREQ_PM' => {
    'Cache::Memcached::Fast' => '0',
    'DBI' => '0',
    'DateTime::Format::Duration' => '0',
    'EntityModel::Class' => '0.002',
    'EntityModel::Log' => '0.001',
    'JSON::XS' => '2.00',
    'Module::Load' => '0',
    'Template' => '2.18',
    'XML::XPath' => '1.00'
  },
  'VERSION' => '0.006',
  'test' => {
    'TESTS' => 't/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



