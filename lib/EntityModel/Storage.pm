package EntityModel::Storage;
BEGIN {
  $EntityModel::Storage::VERSION = '0.005'; # TRIAL
}
use EntityModel::Class {
	transaction	=> { type => 'array', subclass => 'EntityModel::Transaction' },
};

=head1 NAME

EntityModel::Storage - backend storage interface for L<EntityModel>

=head1 VERSION

version 0.005

=head1 SYNOPSIS

See L<EntityModel>.

=head1 DESCRIPTION

See L<EntityModel>.

=head1 METHODS

=cut

=head2 register

Register with L<EntityModel> so that callbacks trigger when further definitions are loaded/processed.

=cut

sub register {
	my $class = shift;
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
	die "Virtual!";
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
	die "Virtual!";
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
	die "Virtual!";
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
	die "Virtual!";
}

=head2 find

Find some entities that match the spec.

=cut

sub find {
	my $self = shift;
	my %args = @_;
	die "Virtual!";
}

=head2 adjacent

Returns the previous and next element for the given ID.

=cut

sub adjacent {
	my $self = shift;
	my %args = @_;
	die "Virtual!";
}

=head2 prev

Returns previous element for the given ID.

=cut

sub prev {
	my $self = shift;
	my ($prev, $next) = $self->adjacent(@_);
	return $prev;
}

=head2 next

Returns next element for the given ID.

=cut

sub next {
	my $self = shift;
	my ($prev, $next) = $self->adjacent(@_);
	return $next;
}

=head2 outer

Returns first and last IDs for the given entity.

=cut

sub outer {
	my $self = shift;
	my %args = @_;
	die "Virtual!";
}

=head2 first

Returns first active ID for the given entity.

=cut

sub first {
	my $self = shift;
	my ($first, $last) = $self->outer(@_);
	return $first;
}

=head2 last

Returns last active ID for the given entity.

=cut

sub last {
	my $self = shift;
	my ($first, $last) = $self->outer(@_);
	return $last;
}

=head2 transaction_start

Mark the start of a transaction.

=cut

sub transaction_start {
	my $self = shift;
	my $tran = shift;

# TODO weaken?
	$self->transaction->push($tran);
	return $self;
}

=head2 transaction_rollback

Roll back a transaction.

=cut

sub transaction_rollback {
	my $self = shift;
	my $tran = shift;
	die "No transaction in progress" unless $self->transaction->count;
	die "Mismatched transaction" unless $tran ~~ $self->transaction->last;
}

=head2 transaction_commit

Commit this transaction to storage - makes everything done within the transaction permanent
(or at least to the level the storage class supports permanence).

=cut

sub transaction_commit {
	my $self = shift;
	my $tran = shift;
	die "No transaction in progress" unless $self->transaction->count;
	die "Mismatched transaction" unless $tran ~~ $self->transaction->last;
}

=head2 transaction_end

Release the transaction on completion.

=cut

sub transaction_end {
	my $self = shift;
	my $tran = shift;
	die "No transaction in progress" unless $self->transaction->count;
	die "Mismatched transaction" unless $tran ~~ $self->transaction->last;
	$self->transaction->pop;
	return $self;
}

sub DESTROY {
	my $self = shift;
	die "Active transactions" if $self->transaction->count;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.