package EntityModel::Deferred;
BEGIN {
  $EntityModel::Deferred::VERSION = '0.011';
}
use EntityModel::Class {
};

=head1 NAME

EntityModel::Deferred - value which is not yet ready

=head1 VERSION

version 0.011

=head1 SYNOPSIS

 use EntityModel;

=head1 DESCRIPTION


=head1 METHODS

=cut

sub new {
	my $class = shift;
	my $self = bless {
		event	=> {
			ready	=> [ ],
			error	=> [ ],
		}
	}, $class;
	return $self;
}

sub queue_callback {
	my $self = shift;
	while(@_) {
		my ($k, $v) = splice @_, 0, 2;
		push @{$self->{event}->{$k}}, $v;
	}
	return $self;
}

sub value {
	my $self = shift;
	die "Value is not yet ready" unless exists $self->{value};
	return $self->{value};
}

sub provide_value {
	my $self = shift;
	$self->{value} = shift;
	$self->dispatch('ready');
}

sub raise_error {
	my $self = shift;
	$self->dispatch('error');
}

sub dispatch {
	my $self = shift;
	my $evt = shift;
	foreach my $handler (@{ $self->{event}->{$evt} }) {
		$handler->($self);
	}
	return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.