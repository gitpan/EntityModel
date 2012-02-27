package EntityModel::Entity;
{
  $EntityModel::Entity::VERSION = '0.015';
}
use EntityModel::Class {
	name		=> { type => 'string' },
	'package'	=> { type => 'string' },
	type		=> { type => 'string' },
	description	=> { type => 'string' },
	primary		=> { type => 'string' },
	constraint	=> { type => 'array', subclass => 'EntityModel::Entity::Constraint' },
	field		=> { type => 'array', subclass => 'EntityModel::Field' },
	field_map	=> { type => 'hash', scope => 'private', watch => { field => 'name' } },
};

=head1 NAME

EntityModel::Entity - entity definition for L<EntityModel>

=head1 VERSION

version 0.015

=head1 SYNOPSIS

See L<EntityModel>.

=head1 DESCRIPTION

See L<EntityModel>.

=head1 METHODS

=cut

=head2 new

Creates a new entity with the given name.

=cut

sub new {
	my $class = shift;
	my $name = shift;
	return bless { name => $name }, $class;
}

=head2 new_field

Helper method to create a new field.

=cut

sub new_field {
	my $self = shift;
	my $name = shift;
	my $param = shift || { };

	my $field = EntityModel::Field->new({ %$param, name => $name });
	return $field;
}

=head2 dependencies

Report on the dependencies for this entity.

Returns a list of L<EntityModel::Entity> instances required for this entity.

=cut

sub dependencies {
	my $self = shift;
	return map { $_->refer->entity } grep { $_->refer } $self->field->list;
}

=head2 matches

Returns true if this entity has identical content to another L<EntityModel::Entity>.

=cut

sub matches {
	my ($self, $dst) = @_;
	die "Not an EntityModel::Entity" unless $dst->isa('EntityModel::Entity');

	return 0 if $self->name ne $dst->name;
	return 0 if $self->field->count != $dst->field->count;
	return 0 unless $self->primary ~~ $dst->primary;

	my @srcF = sort { $a->name cmp $b->name } $self->field->list;
	my @dstF = sort { $a->name cmp $b->name } $dst->field->list;
	while(@srcF && @dstF) {
		my $srcf = shift(@srcF);
		my $dstf = shift(@dstF);
		return 0 unless $srcf && $dstf;
		return 0 unless $srcf->name eq $dstf->name;
	}
	return 0 if @srcF || @dstF;
	return 1;
}

sub dump {
	my $self = shift;
	my $out = shift || sub {
		print join(' ', @_) . "\n";
	};

	$self;
}

sub asString { shift->name }

=head2 create_from_definition

Create a new L<EntityModel::Entity> from the given definition (hashref).

=cut

sub create_from_definition {
	my $class = shift;
	my $def = shift;
	my $self = $class->new(delete $def->{name});
	
	if(my $field = delete $def->{field}) {
		$self->add_field(EntityModel::Field->create_from_definition($_)) foreach @$field;
	}

# Apply any remaining parameters
	$self->$_($def->{$_}) foreach keys %$def;
	return $self;
}

=head2 add_field

Add a new field to this entity.

=cut

sub add_field {
	my $self = shift;
	my $field = shift;
	$self->field->push($field);
	return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
