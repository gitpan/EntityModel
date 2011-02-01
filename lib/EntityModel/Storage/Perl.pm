package EntityModel::Storage::Perl;
BEGIN {
  $EntityModel::Storage::Perl::VERSION = '0.001'; # TRIAL
}
use EntityModel::Class {
	_isa		=> [qw{EntityModel::Storage}],
	schema		=> { type => 'string' },
	entity		=> { type => 'array', subclass => 'EntityModel::Entity' },
};

=head1 NAME

EntityModel::Storage::Perl - backend storage interface for L<EntityModel>

=head1 VERSION

version 0.001

=head1 SYNOPSIS

See L<EntityModel>.

=head1 DESCRIPTION

See L<EntityModel>.

This does not really qualify as a 'storage' module, since it's intended purely for use in
testing, providing an ephemeral backing store for entities which will disappear on program
termination.

=cut

# Used for holding any entities that have been created
my %EntityMap;

# Max ID information
my %EntityMaxID;

=head1 METHODS

=cut

=head2 setup

=cut

sub setup {
	my $self = shift;
	my %args = %{+shift};
	$self->schema(delete $args{schema});
	return $self;
}

=head2 apply_model

=cut

sub apply_model {
	my $self = shift;
	my $model = shift;
	logDebug("Apply model");
	$self->apply_model_and_schema($model);
}

=head2 apply_model_and_schema

=cut

sub apply_model_and_schema {
	my $self = shift;
	my $model = shift;

	my @pending = $model->entity->list;
	my @existing;

	ITEM:
	while(@pending) {
		my $entity = shift(@pending);

		my @deps = $entity->dependencies;
		my @pendingNames = map { $_->name } @pending;

		# Include current entity in list of available entries, so that we can allow self-reference
		foreach my $dep (@deps) {
			unless(grep { $dep->name ~~ $_->name } @pending, @existing, $entity) {
				logError("%s unresolved (pending %s, deps %s for %s)", $dep->name, join(',', @pendingNames), join(',', @deps), $entity->name);
				die "Dependency error";
			}
		}

		my @unsatisfied = grep { $_ ~~ [ map { $_->name } @deps ] } @pendingNames;
		if(@unsatisfied) {
			logInfo("%s has %d unsatisfied deps, postponing: %s", $entity->name, scalar @unsatisfied, join(',',@unsatisfied));
			push @pending, $entity;
			next ITEM;
		}

		$self->apply_entity($entity);
		push @existing, $entity;
	}
	return $self;
}

=head2 apply_entity

=cut

sub apply_entity {
	my $self = shift;
	my $entity = shift;
	die "Entity exists already: " . $entity->name if exists $EntityMap{$entity->name};

	$self->entity->push($entity);
	$EntityMap{$entity->name} = {
		entity	=> $entity,
		max_id	=> 0,
	};
	return $self;
}

=head2 read_primary

Get the primary keys for a table.

=cut

sub read_primary {
	my $self = shift;
	my $entity = shift;
	return $EntityMap{$entity->name}->{entity}->primary->list;
}

=head2 read_fields

Read all fields for a given table.

Since this is typically a slow query, we cache the entire set of fields for all tables on
the first call.

=cut

sub read_fields {
	my $self = shift;
	my $entity = shift;
	return $EntityMap{$entity->name}->{entity}->field->list;
}

=head2 table_list

Get a list of all the existing tables in the schema.

=cut

sub table_list {
	my $self = shift;
	return map { $_->{entity} } values %EntityMap;
}

=head2 field_list

Returns a list of all fields for the given table.

=cut

sub field_list {
	my $self = shift;
	my $entity = shift;
	return $EntityMap{$entity->name}->{entity}->field->list;
}

=head2 read

Reads the data for the given entity and returns hashref with the appropriate data.

Parameters:

=over 4

=item * entity - L<EntityModel::Entity>

=item * id - ID to read data from

=back

=cut

sub read {
	my $self = shift;
	my %args = @_;
	die "Entity not found" unless exists $EntityMap{$args{entity}->name};
	return $EntityMap{$args{entity}->name}->{store}->{$args{id}};
}

sub _next_id {
	my $self = shift;
	my %args = @_;
	die "Entity not found" unless exists $EntityMap{$args{entity}->name};
	$EntityMaxID{$args{entity}->name} ||= 0;
	return ++$EntityMaxID{$args{entity}->name};
}

=head2 create

Creates new entry for the given L<EntityModel::Entity>.

Parameters:

=over 4

=item * entity - L<EntityModel::Entity>

=item * data - actual data values

=back

=cut

sub create {
	my $self = shift;
	my %args = @_;
	my $id = $self->_next_id(%args);
	$args{id} = $id;
	$args{data} = {
		%{$args{data}},
		id => $id
	};
	$self->store(%args);
	return $id;
}

=head2 store

Stores data to the given entity and ID.

Parameters:

=over 4

=item * entity - L<EntityModel::Entity>

=item * id - ID to store data to

=item * data - actual data values

=back

=cut

sub store {
	my $self = shift;
	my %args = @_;
	die "Entity not found" unless exists $EntityMap{$args{entity}->name};
	$EntityMap{$args{entity}->name}->{store}->{$args{id}} = $args{data};
}

=head2 remove

Removes given ID from storage.

Parameters:

=over 4

=item * entity - L<EntityModel::Entity>

=item * id - ID to store data to

=back

=cut

sub remove {
	my $self = shift;
	my %args = @_;
	die "Entity not found" unless exists $EntityMap{$args{entity}->name};
	delete $EntityMap{$args{entity}->name}->{store}->{$args{id}};
}

=head2 find

=cut

sub find {
	my $self = shift;
	my $class = shift;
	die "Virtual!";
}

=head2 adjacent

=cut

sub adjacent {
	my $self = shift;
	my %args = @_;
	die "Entity not found" unless exists $EntityMap{$args{entity}->name};

	my $entity = $args{entity};
	my $id = $args{id};

# You shouldn't be using this module in production code anyway...
	my ($prev) = reverse grep {
		$_ < $id
	} sort keys %{$EntityMap{$entity->name}->{store}};
	my ($next) = grep {
		$_ > $id
	} sort keys %{$EntityMap{$entity->name}->{store}};

	return ($prev, $next);
}

=head2 outer

=cut

sub outer {
	my $self = shift;
	my %args = @_;
	my $entity = $args{entity};
	die "Entity not found" unless exists $EntityMap{$entity->name};

	my (@entries) = sort keys %{$EntityMap{$entity->name}->{store}};
	my $first = shift @entries;
	my $last = pop @entries;
	return ($first, $last);
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.