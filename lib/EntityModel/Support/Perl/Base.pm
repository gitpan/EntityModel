package EntityModel::Support::Perl::Base;
BEGIN {
  $EntityModel::Support::Perl::Base::VERSION = '0.001'; # TRIAL
}
use EntityModel::Class {
};

=head1 NAME

EntityModel::Support::Perl::Base - base class for entity instances

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 say $_->name foreach Entity::Thing->find({name=>'test'});

=head1 DESCRIPTION

All entities are derived from this base class by default.

=cut

use Time::HiRes qw{time};
use DateTime;
use DateTime::Format::Strptime;
use Tie::Cache::LRU;

=head2 new

Instantiate from an ID or a pre-fabricated object (hashref).

=cut

sub new {
	my $class = shift;
	my $spec = shift || {};
	my $self;
	if(ref $spec eq 'HASH') {
		$self = $class->_spec_from_hashref($spec);
	} elsif(!@_ || ref $spec eq 'ARRAY') {
		$self = $class->_storage->read(
			entity	=> $class->_entity,
			id	=> $spec
		) or return EntityModel::Error->new('Could not instantiate');
	} else {
		$self = $class->_spec_from_hashref({ $spec, @_ });
	}
	$self ||= {};

	bless $self, $class;
	return $self;
}

=head2 _spec_from_hashref

Private method to generate hashref containing spec information suitable for bless to requested class,
given a hashref which represents the keys/values for the object.

This will flatten any Entity objects down to the required ID key+values.

=cut

sub _spec_from_hashref {
	my $class = shift;
	my $spec = shift;
	my %details;
	foreach my $k (keys %$spec) {
		if(ref $spec->{$k} && eval { $spec->{$k}->isa(__PACKAGE__) }) {
			$details{"id$k"} = $spec->{$k}->id;
		} else {
			$details{$k} = $spec->{$k};
		}
	}
	return \%details;
}

=head2 create

Create a new object.

Takes a hashref, and sets the flag so that ->commit does the insert.

=cut

sub create {
	my $class = shift;
	my $self = $class->new(@_);
	$self->{ _insert_required } = 1;
	return $self;
}

=head2 find

Search for entities that match the given spec.

Generates a query from the spec, and uses that to locate any matching objects, instantiating them as required.

=over 4

=item * $spec - hashref (or plain hash) of search options

=back

Example:

 Entity::Thing->find(
 	name => 'test'
 );

TODO Not yet supported

=cut

sub _find_query {
	my $class = shift;
	my $spec = shift;
	my $opt = shift || [ ];

# Normalise the options if we had any
	$opt = [ %$opt ] if ref $opt eq 'HASH';
	$opt = [ $opt ] unless ref $opt eq 'ARRAY';

#	my $q = EntityModel::Query->new(
#		select	=> [ $class->_entity->field->list ],
#		from	=> $class->_entity,
#		  $spec
#		? (where	=> $spec)
#		: (),
#		@$opt
#	);
#
#	logDebug($q->sqlString);
	return;
}

sub find {
	my $class = shift;
	my $q = $class->_find_query(@_) or return;
	my @rslt = $q->results();
	return unless @rslt;

# Pass error back up if we get one
	return @rslt if eval { $rslt[0]->isa('EntityModel::Error'); };
	return grep { $_ } map { $class->new($_) } @rslt;
}

sub iterate {
	my $class = shift;
	my $code = pop;
	my $q = $class->_find_query(@_);
	$q->iterate(sub {
		my $self = $class->new($_[0]);
		$code->($self) if $self;
	});
	return $class;
}

sub _extract_data {
	my $self = shift;
	return {
		map { $_ => $self->$_ } grep { exists $self->{$_} } map { $_->name } $self->_entity->field->list
	};
}

=head2 _update

Write current values back to storage.

=cut

sub _update {
	my $self = shift;
	my %args = @_;

	my $primary = $self->_entity->primary;
	$self->_storage->store(
		entity	=> $self->_entity,
		id	=> $self->$primary,
		data	=> $self->_extract_data
	);
	return $self;
}

=head2 _select

Populate this instance with values from the database.

=cut

sub _select {
	my $self = shift;
	my %args = @_;

	my $primary = $self->_entity->primary;
	die "Undef primary element found for $self" if grep !defined, $primary;

	my $data = $self->_storage->read(
		entity	=> $self->_entity,
		id	=> $self->$primary,
	) or return EntityModel::Error->new("Failed to read");
	$self->{$_} = $data->{$_} for keys %$data;
	return $self;
}

=head2 _pending_insert

Returns true if this instance is due to be committed to the database.

=cut

sub _pending_insert { return shift->{_insert_required} ? 1 : 0; }

=head2 _pending_update

Returns true if this instance is due to be committed to the database.

=cut

sub _pending_update { return shift->{_update_required} ? 1 : 0; }

=head2 _insert

Insert this instance into the db.

=cut

sub _insert {
	my $self = shift;
	my %args = @_;
	my $primary = $self->_entity->primary;
	# FIXME haxx
	delete $self->{$primary} unless defined $self->{$primary};

	my $id = $self->_storage->create(
		entity	=> $self->_entity,
		data	=> $self->_extract_data,
	);
	$self->{id} = $id;
	delete $self->{_insert_required};
	return $self;
}

=head2 commit

Commit any pending changes to the database.

=cut

sub commit {
	my $self = shift;
	$self->_insert(@_) if $self->_pending_insert;
	$self->_update(@_) if $self->_pending_update;
	return $self;
}

=head2 revert

Revert any pending changes to the database.

=cut

sub revert {
	my $self = shift;
	return if $self->_pending_insert;
	return $self->_select(@_);
}

sub waitFor {
	my $self = shift;

}

=head2 id

Primary key (id) for this instance.

=cut

sub id {
	my $self = shift;
	logStack("Self is not an instance?") unless ref $self;
	if(@_) {
		$self->{id} = shift;
		return $self;
	}
	return $self->{id} if exists $self->{id};
#	logDebug("Expect from " . $_) foreach $self->_entity->list_primary;
	$self->{id} = join('-', map { $self->{$_} // 'undef' } $self->_entity->primary);
	$self->{$_} = $self->{id} foreach $self->_entity->primary;
#	logDebug("Found ID as " . $self->{id});
	return $self->{id};
}

=head2 fromID

Instantiate from an ID.

=cut

sub fromID {
	my $class = shift;
	my $id = shift;

#	logDebug("Instantiate " . ($id // 'undef'));
	my $self = bless { }, $class;
	$self->{id} = $id;
	$self->{$_} = $id foreach $self->_entity->primary;
	$self->{_incomplete} = 1;
	return EntityModel::Error->new('Permission denied') if $self->can('hasAccess') && !$self->hasAccess('read');
	return $self;
}

=head2 remove

Remove this instance from the database.

=cut

sub remove {
	my $self = shift;
	$self->_storage->remove(
		entity	=> $self->_entity,
		id	=> $self->id
	) or return EntityModel::Error->new("Failed to remove");
	return $self;
}

=head2 _view

Returns the view corresponding to this object.

=cut

sub _view {
	my $self = shift;
	return $self->_viewClass->new(instance => $self) if $self->can('_viewClass');
	return EntityModel::View->new(
		instance	=> $self,
	);
}

sub _paged {
	my $class = shift;
	return EntityModel::Pager->new({
		entity => $class
	});
}

# wrong place?
my %TimestampCache;
tie %TimestampCache, 'Tie::Cache::LRU', 50000;

sub _timeStamp {
	my $self = shift;
	my $fieldName = shift;
	my $v = $self->{$fieldName};
	return undef unless $fieldName && $v;
	return $TimestampCache{$v} if exists $TimestampCache{$v};

	my $ts;
	if($self->{$fieldName} =~ m/^(\d+)-(\d+)-(\d+)[ T](\d+):(\d+):(\d+)(?:\.(\d{1,9}))?/) {
		$ts = DateTime->new(
			year		=> $1,
			month		=> $2,
			day		=> $3,
			hour		=> $4,
			minute		=> $5,
			second		=> $6,
			nanosecond	=> $7 ? ($7 . ('0' x (9 - length($7)))) : 0,
			formatter	=> DateTime::Format::Strptime->new(pattern => '%Y-%m-%d %H:%M:%S.%3N')
		);
	}
	$TimestampCache{$v} = $ts;
	return $ts;
}

END { logDebug("Had %d entries in the timestamp cache", (tied %TimestampCache)->curr_size); }

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.