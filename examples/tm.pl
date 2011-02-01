#!/usr/bin/perl 
use strict;
use warnings;
use EntityModel;

my $db = EntityModel::DB->new;
my $em;
warn "Start transaction";
$db->transaction(sub {
	warn "In transaction";
	$em = EntityModel->new(
		'Load::XML' => \q{
<entitymodel>
  <name>EMTest</name>
  <schema>emtest</schema>
  <table>
    <name>article</name>
    <schema>emtest</schema>
    <primary>idarticle</primary>
    <field>
      <name>idarticle</name>
      <type>bigserial</type>
      <null>false</null>
    </field>
    <field>
      <name>title</name>
      <type>varchar</type>
      <null>true</null>
    </field>
    <field>
      <name>content</name>
      <type>varchar</type>
      <null>true</null>
    </field>
  </table>
</entitymodel>},
		'DB'	 	=> { db => $db },
		'Apply::SQL'	=> { schema => 'tomtest' },
		'Apply::Perl'	=> {
			namespace => 'Entity',
			baseclass => 'EntityModel::EntityBase',
		},
	);
	warn "Done transaction";
	print "Had em $em";
});
warn "Finished transaction";
