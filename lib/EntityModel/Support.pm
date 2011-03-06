package EntityModel::Support;
BEGIN {
  $EntityModel::Support::VERSION = '0.010';
}
use EntityModel::Class {
};

=head1 NAME

EntityModel::Support - language support for L<EntityModel>

=head1 VERSION

version 0.010

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

=head2 apply_model

Apply the given model.

=cut

sub apply_model {
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

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.