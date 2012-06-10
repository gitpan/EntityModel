package EntityModel::Transaction;
{
  $EntityModel::Transaction::VERSION = '0.017';
}
use Scalar::Util qw(refaddr);
use EntityModel::Class {
	'~~'	=> 1,
};

=head1 NAME

EntityModel::Transaction - transaction co-ordinator

=head1 VERSION

version 0.017

=head1 SYNOPSIS

See L<EntityModel>.

=head1 DESCRIPTION

Contacts each L<EntityModel::Storage> instance and requests that they join a new
transaction.

See L<EntityModel>.

=head1 METHODS

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $model = delete $args{model} or die "No model provided";
	my $code = delete $args{code} or die "No code";

	my $self = bless {
	}, $class;

# Stash the list of EntityModel::Storage instances early, in case we add any during the transaction
	my @storage = $model->storage->list;
	$_->transaction_start($self) for @storage;
	my $rslt = $self;
	try {
		$code->();
		$_->transaction_commit($self) for @storage;
	} catch {
		logError($_);
		$rslt = EntityModel::Error->new($_);
		$_->transaction_rollback($self) for @storage;
	};
	$_->transaction_end($self) for @storage;
	return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
