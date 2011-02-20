use strict;
use warnings;

use Test::More skip_all => 'incomplete';
use EntityModel::Plugin::Apply::SQL;

# Create a basic model but don't apply the SQL part yet
my $model = EntityModel->new(
	'Load::XML' => \q{
<entitymodel>
  <name>EMTest</name>
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
	DB	=> { db => EntityModel::DB->new },
);
ok($model->entity->count, 'have entities');

# Set up the SQL plugin from the model information
my $apply = new_ok('EntityModel::Plugin::Apply::SQL' => [
	$model,
]) or die $@;
$apply->schema($model->schema);

# Test the fundamental handling before we go ahead and create any tables
$model->db->transaction(sub {
	# Grab the first entity
	ok(my $tbl = $model->entity->first, 'get first entity');
	isa_ok($tbl, 'EntityModel::Entity');

	# Check that we quote correctly
	is($apply->quotedTableName($tbl), '"emtest"."article"', 'quoted table name for ' . $tbl->name . ' is correct');
	is($apply->quotedFieldName($_), '"' . $_->name . '"', 'quoted field name for ' . $_->name . ' is correct') foreach $tbl->field->list;

	# Now have a look at the create/drop statements
	my ($sql) = $apply->createTableQuery($tbl);
	is($sql, 'create table "emtest"."article" ("idarticle" bigserial, "title" varchar, "content" varchar)', 'create statement is correct');
	($sql) = $apply->removeTableQuery($tbl);
	is($sql, 'drop table "emtest"."article"', 'drop statement is also correct');

	# Before we try to do anything, let's read from the DB to make sure it starts off empty
	ok(!$apply->schemaExists, 'schema does not exist at start') or die "Schema seems to be in place already, failed test run?";
	ok($apply->createSchema, 'create schema');
	ok($apply->schemaExists, 'schema now exists') or die "Schema could not be created";
	my @tbl = $apply->readTables;
	ok(!@tbl, 'no tables to start with');

	# Now create this entity
	ok($apply->createTable($tbl), 'attempt to create the entity');

	# Read back all the details and verify that they match
	my ($fromDB) = $apply->readTables;
	ok($fromDB, 'now have a table in the database');
	is($fromDB->{name}, $tbl->name, 'name matches');
	my @fields = $apply->readFields($tbl);
	ok(@fields, 'had fields');
	# We want to check that the ordering on our fields is consistent, so we build a list of pairs and check each entry matches.
	my @entityFields = $tbl->field->list;
	my @pairs = map { [ shift(@fields), shift(@entityFields) ] } 0..$#entityFields;
	is($_->[0]->{name}, $_->[1]->name, "name matches for " . $_->[1]->name) for @pairs;

	# Clean up the schema on exit
	ok($apply->removeSchema, 'drop schema');
	ok(!$apply->schemaExists, 'schema no longer exists') or die "Schema removal failed";
});

