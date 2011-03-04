package EntityModel::Definition;
BEGIN {
  $EntityModel::Definition::VERSION = '0.009';
}
use EntityModel::Class {
};

=head1 NAME

EntityModel::Definition - definition support for L<EntityModel>

=head1 VERSION

version 0.009

=head1 SYNOPSIS

See L<EntityModel>.

=head1 DESCRIPTION

See L<EntityModel>.

=head1 METHODS

=cut

=head2 load

Generic load method, passing file or string to the appropriate L<load_file> or L<load_string> methods.

=cut

sub load {
	my $self = shift;
	my %args = @_;

	my $src = delete $args{source};
	my ($k, $v);
	if(ref $src ~~ 'HASH') {
		($k, $v) = %$src;
	} elsif(ref $src ~~ 'ARRAY') {
		($k, $v) = @$src;
	} else {
		$k = shift;
	}
	logDebug("Trying [%s] as [%s] => [%s]", $self, $k, $v);
	die 'Nothing passed' unless defined $k;

	my $structure;
	$structure ||= $self->load_file($v) if $k eq 'file' && defined $v;
	$structure ||= $self->load_string($v) if $k eq 'string' && defined $v;

# Support older interface - single parameter, scalarref for string, plain scalar for XML filename
	$structure ||= $self->load_file($k) if !ref($k) && !$v;
	$structure ||= $self->load_string($$k) if ref($k) && !$v;
	die 'Unable to load ' . $self . " from [$k] and [$v]" unless $structure;
	return $self->apply_model_from_structure(
		model		=> $args{model},
		structure	=> $structure
	);
}

=head2 apply_model_from_structure

=cut

sub apply_model_from_structure {
	my $self = shift;
	my %args = @_;
	my $model = delete $args{model};
	my $definition = delete $args{structure};

	if(my $name = delete $definition->{name}) {
		$model->name($name);
	}

	if(my $entity = delete $definition->{entity}) {
		my @entity_list = @$entity;
		$self->add_entity_to_model(
			model	=> $model,
			definition => $_
		) foreach @$entity;
	}
	foreach my $k (keys %$definition) {
		$model->handle_item(
			item	=> $k,
			data	=> $definition->{$k}
		);
	}
	$model->resolve_entity_dependencies;
	return $self;
}

=head2 add_entity_to_model

Create a new entity and add it to the given model.

=cut

sub add_entity_to_model {
	my $self = shift;
	my %args = @_;

	my $model = delete $args{model};
	my $def = delete $args{definition};
	my $entity = EntityModel::Entity->create_from_definition($def);
	$model->add_entity($entity);
	return $self;
}

=head2 C<register>

=cut

sub register {
	my $self = shift;

}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.