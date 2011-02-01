package EntityModel::Cache::MemcachedFast;
BEGIN {
  $EntityModel::Cache::MemcachedFast::VERSION = '0.001'; # TRIAL
}
use EntityModel::Class {
	_isa	=> [qw(EntityModel::Cache)],
	ketama	=> { type => 'int', default => 150 },
	server	=> { type => 'array', subclass => 'string' },
	mc	=> { type => 'Cache::Memcached::Fast', scope => 'private' }
};

=head1 NAME

EntityModel::Cache::MemcachedFast - L<Cache::Memcached::Fast>-backed cache layer

=head1 VERSION

version 0.001

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

use Cache::Memcached::Fast;
use IO::Compress::Gzip;
use IO::Uncompress::Gunzip;
use Data::Dumper;

our $cache;

=head1 METHODS

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless { }, $class;

	$self->server->push($_) for split /,/, (delete($args{server}) || '');
	die "No servers defined" unless $self->server->count;
	$self->ketama(delete $args{ketama}) if exists $args{ketama};
	$self->connect;
	return $self;
}

sub get {
	my $self = shift;
	die 'This is an instance method' unless ref($self);
	return $self->mc->get(@_);
}

sub remove {
	my $self = shift;
	die 'This is an instance method' unless ref($self);
	return $self->mc->remove(@_);
}

sub incr {
	my $self = shift;
	die 'This is an instance method' unless ref($self);
	return $self->mc->incr(@_);
}

sub decr {
	my $self = shift;
	die 'This is an instance method' unless ref($self);
	return $self->mc->decr(@_);
}

sub set {
	my $self = shift;
	die 'This is an instance method' unless ref($self);
	return $self->mc->set(@_);
}

sub atomic {
	my $self = shift;
	die 'This is an instance method' unless ref($self);
	my $k = shift;
	my $f = shift;
	my $mc = $self->mc;

	my $v = $mc->get($k);
	if($v) {
		logDebug('[%s] is cached, %d bytes', $k, length($v));
		return $v;
	}

	my $lock = $mc->gets($k);
	$v = $f->($k); # old memcached without cas support may die here

	if(!defined($lock)) {
		$mc->set($k, $v, 5);
		return $v;
	}

	my $rslt;
	$$lock[1] = $v;
	$rslt = $mc->cas($k, @$lock);
	logDebug(sub { "Got result: [%s]", Dumper $rslt });
	return $v;
}

sub connect {
	my $self = shift;
	unless($self->mc) {
		$self->mc(Cache::Memcached::Fast->new({
			servers			=> $self->server->arrayref,
			namespace		=> 'EntityModel:',
			connect_timeout		=> 0.2,
			io_timeout		=> 0.5,
			close_on_error		=> 1,
			compress_threshold	=> 50_000,
			compress_ratio		=> 0.9,
			compress_methods	=> [
				\&IO::Compress::Gzip::gzip,
				\&IO::Uncompress::Gunzip::gunzip
			],
			max_failures		=> 3,
			failure_timeout		=> 2,
			ketama_points		=> $self->ketama,
			nowait			=> 1,
			hash_namespace		=> 1,
			serialize_methods	=> [
				\&Storable::freeze,
				\&Storable::thaw
			],
			utf8			=> 1
		}) or die 'No memcached');
	}
	return $self->mc;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.