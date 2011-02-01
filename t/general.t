use strict;
use warnings;

use Test::More tests => 13;
use EntityModel;

# Read in the model definition first
my $model = EntityModel->new->load_from(
	XML => { string => q{
<entitymodel>
  <name>EMTest</name>
  <schema>emtest</schema>
  <entity>
    <name>article</name>
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
    <field>
      <name>idauthor</name>
      <type>bigint</type>
      <null>true</null>
      <refer>
        <table>author</table>
        <field>idauthor</field>
        <delete>cascade</delete>
        <update>cascade</update>
      </refer>
    </field>
  </entity>
  <entity>
    <name>author</name>
    <primary>idauthor</primary>
    <field>
      <name>idauthor</name>
      <type>bigserial</type>
      <null>false</null>
    </field>
    <field>
      <name>name</name>
      <type>varchar</type>
    </field>
    <field>
      <name>email</name>
      <type>varchar</type>
    </field>
  </entity>
</entitymodel>}
});

# Check that we loaded okay
is($model->entity->count, 2, 'have entities');

$model->add_storage(Perl => { });
$model->add_support('Perl' => {
	namespace => 'Entity',
});

foreach my $type (qw/Entity::Article Entity::Author/) {
	can_ok($type, $_) for qw/new create find/;
}

my $id;
$model->transaction(sub {
	ok(my $author = Entity::Author->create(
		name	=> 'Author name',
		email	=> 'author@example.com',
	), 'create new author');
	is($author->name, 'Author name', 'name matches');
	is($author->email, 'author@example.com', 'email matches');
	$author->commit;
# TODO re-enable these when the Perl storage backend supports them
#	my ($copy) = Entity::Author->find({
#		name	=> 'Author name',
#	});
#	is($copy->id, $author->id, 'can find same entry by searching name field') or die "not found";
#	($copy) = Entity::Author->find({
#		email	=> 'author@example.com',
#	});
#	is($copy->id, $author->id, 'can find same entry by searching email field');
#	($copy) = Entity::Author->find({
#		name	=> 'Author name',
#		email	=> 'author@example.com',
#	});
#	is($copy->id, $author->id, 'can find same entry by searching both fields');
	$id = $author->id;
});

ok(my $author = Entity::Author->new($id), 'can do a ->new lookup');
is($author->id, $id, 'ID matches');
is($author->name, 'Author name', 'name matches');

