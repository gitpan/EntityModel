package EntityModel::Query::Update;
BEGIN {
  $EntityModel::Query::Update::VERSION = '0.001'; # TRIAL
}
use EntityModel::Class {
	_isa => [qw{EntityModel::Query}],
};

=head1 NAME

EntityModel::Query::Update

=head1 VERSION

version 0.001

=head1 SYNOPSIS

See L<Entitymodel::Query>.

=head1 DESCRIPTION

See L<Entitymodel::Query>.

=cut

=head1 METHODS

=cut

=head2 type

=cut

sub type { 'update'; }

=head2 keyword_order

=cut

sub keyword_order { qw{type from join fields where order offset limit}; }

=head2 fromSQL

=cut

sub fromSQL {
	my $self = shift;
	my $from = join(', ', map { $_->asString } $self->list_from);
	return unless $from;
	return $from;
}

=head2 fieldsSQL

=cut

sub fieldsSQL {
	my $self = shift;
	my $fields = join(', ', map {
		$_->asString . ' = ' . $_->quotedValue
	} $self->list_field);
	return unless $fields;
	return 'set ' . $fields;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.