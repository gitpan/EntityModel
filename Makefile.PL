
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Cross-language event-driven ORM',
  'AUTHOR' => 'Tom Molesworth <cpan@entitymodel.com>',
  'BUILD_REQUIRES' => {
    'Test::Class' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'EntityModel',
  'EXE_FILES' => [
    'bin/entitymodel',
    'bin/entitymodel'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'EntityModel',
  'PREREQ_PM' => {
    'CPS' => '0.10',
    'DateTime::Format::Duration' => '0',
    'EntityModel::Class' => '0.008',
    'EntityModel::Log' => '0.002',
    'JSON::XS' => '2.00',
    'Mixin::Event::Dispatch' => '0.002',
    'Module::Load' => '0',
    'Template' => '2.18',
    'XML::XPath' => '1.00'
  },
  'VERSION' => '0.013',
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



