package EntityModel::Query::Except;
{
  $EntityModel::Query::Except::VERSION = '0.017';
}
use EntityModel::Class {
	_isa => [qw{EntityModel::Query::SubQuery}],
	subquery => { type => 'array', subclass => 'EntityModel::Query' }
};

=head1 NAME

EntityModel::Query::Except - support for EXCEPT set logic

=head1 VERSION

version 0.017

=head1 SYNOPSIS

See L<Entitymodel::Query>.

=head1 DESCRIPTION

See L<Entitymodel::Query>.

=cut

=head1 METHODS

=cut

sub subtype { 'except' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
