package EntityModel::Template;
BEGIN {
  $EntityModel::Template::VERSION = '0.001'; # TRIAL
}
use EntityModel::Class { };

=head1 NAME

EntityModel::Template - template handling for L<EntityModel>

=head1 VERSION

version 0.001

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Template;
use Template::Stash;
use File::Basename;
use Tie::Cache::LRU;
use DateTime::Format::Duration;
use POSIX qw/floor/;

tie my %longDateHash, 'Tie::Cache::LRU', 5000;
tie my %shortDateHash, 'Tie::Cache::LRU', 5000;

my $templateCache;

our $BasePath = '.';

=head2 fromNow

Duration from/since now

=cut

sub fromNow {
	my $v = shift;
	return ' ' unless $v;
	$v = DateTime->from_epoch(epoch => $1) if !ref($v) && $v =~ /^(\d+)$/;
	my $delta = $v->epoch - time;
	my $neg;
	if($delta < 0) {
		$neg = 1;
		$delta = -$delta;
	}
	my @p;
	my @match = (
		second => 60,
		minute => 60,
		hour => 24,
		day => 30,
		month => 12,
		year => 0
	);
	while($delta && @match) {
		my $k = shift @match;
		my $m = shift @match;
		my $unit = $m ? ($delta % $m) : $delta;
		$delta = floor($delta / $m) if $m;
		unshift @p, "$unit $k" . ($unit != 1 ? 's' : '');
	}
# Don't show too much resolution 
	@p = splice(@p, 0, 2) if @p > 2;
	my $pattern = join(', ', @p);

	return $pattern . ($neg ? ' ago' : ' from now');
}

BEGIN {
# Convenience functions so we can do something.arrayref and be sure to get back something FOREACH-suitable
	$Template::Stash::LIST_OPS->{ arrayref } = sub {
		my $list = shift;
		return $list;
	};
	$Template::Stash::HASH_OPS->{ arrayref } = sub {
		my $hash = shift;
		return [ $hash ];
	};
# hashops since we have datetime object... in theory. 
	$Template::Stash::HASH_OPS->{ msDuration } = sub {
		my $v = shift;
		return DateTime::Format::Duration->new(pattern => '%H:%M:%S.%3N')->format_duration($v);
	};
	$Template::Stash::HASH_OPS->{ fromNow } = sub {
		my $v = shift;
		return fromNow($v);
	};
	$Template::Stash::HASH_OPS->{ 'ref' } = sub {
		my $scalar = shift;
		return ref $scalar;
	};
	$Template::Stash::SCALAR_OPS->{ arrayref } = sub {
		my $scalar = shift;
		return [ $scalar ];
	};
	$Template::Stash::SCALAR_OPS->{ trim } = sub {
		my $scalar = shift;
		$scalar =~ s/^\s+//ms;
		$scalar =~ s/\s+$//ms;
		return $scalar;
	};
	$Template::Stash::SCALAR_OPS->{ js } = sub {
		my $str = join('', @_);
		$str =~ s/"/\\"/ms;
		return '"' . $str . '"';
	};
}

sub new {
	my $class = shift;
	my $self = bless { data => { } }, $class;
	$self->{template} = $templateCache if $templateCache;
	return $self;
}

=head2 longDate

Long date format filter.

=cut

sub longDate {
	my ($v, $fmt) = @_;
	return ' ' unless $v;
	unless ($longDateHash{$v}) {
		my $dt;
		if($v =~ m/^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})(?:\.(\d+))?$/) {
			my ($year, $month, $day, $hour, $minute, $second, $us) = ($1, $2, $3, $4, $5, $6, $7);
			$dt = DateTime->new(
				year		=> $year,
				month		=> $month,
				day		=> $day,
				hour		=> $hour,
				minute		=> $minute,
				second		=> $second,
				nanosecond	=> 1000 * ($us // 0)
			);
		} else {
			$dt = DateTime->from_epoch(epoch => $v);
		}
		$longDateHash{$v} = $dt->strftime('%e %b %Y, %l:%M %P');
	}
	return $longDateHash{$v};
}

=head2 shortDate

Short date format filter.

=cut

sub shortDate {
	my ($v, $fmt) = @_;
	return ' ' unless $v;
	unless ($shortDateHash{$v}) {
		my $dt;
		if($v =~ m/^(\d+)-(\d+)-(\d+)/) {
			my ($year, $month, $day) = ($1, $2, $3);
			$dt = new DateTime(
				year		=> $year,
				month		=> $month,
				day		=> $day,
			);
		} else {
			$dt = DateTime->from_epoch(epoch => $v);
		}
		my $suffix = 'th';
		if(($dt->day % 10) == 1 && ($dt->day != 11)) {
			$suffix = 'st';
		} elsif(($dt->day % 10) == 2 && ($dt->day != 12)) {
			$suffix = 'nd';
		} elsif(($dt->day % 10) == 3 && ($dt->day != 13)) {
			$suffix = 'rd';
		}
		$shortDateHash{$v} = $dt->strftime("%d$suffix %b");
	}
	return $shortDateHash{$v};
}

=head2 ymdDate

YMD date filter

=cut

sub ymdDate {
	my ($v, $fmt) = @_;
	return ' ' unless $v;
	my $dt;
	if($v =~ m/^(\d+)-(\d+)-(\d+)/) {
		my ($year, $month, $day) = ($1, $2, $3);
		return sprintf("%04d-%02d-%02d", $year, $month, $day);
	} else {
		$dt = DateTime->from_epoch(epoch => $v);
	}
	return $dt->strftime('%Y-%m-%d');
}

=head2 tidyYMD

YMD date filter

=cut

sub tidyYMD {
	my ($v, $fmt) = @_;
	return ' ' unless $v;
	my $dt;
	if($v =~ m/^(\d+)-(\d+)-(\d+)/) {
		my ($year, $month, $day) = ($1, $2, $3);
		return sprintf("%04d-%02d-%02d", $year, $month, $day);
	} else {
		$dt = DateTime->from_epoch(epoch => $v);
		return $dt->strftime('%Y-%m-%d');
	}
}

=head2 trackDuration

Convert duration to MM:SS representation.

=cut

sub trackDuration {
	my ($v, $fmt) = @_;
	return ' ' unless $v;

	return sprintf('%02d:%02d', int($v / 60), int($v % 60));
}

=head2 template

Return the TT2 object, created as necessary.

=cut

sub template {
	my $self = shift;
	unless($self->{template}) {
		# We want access to _ methods, such as _view, so disable this.
		undef $Template::Stash::PRIVATE;

		my @early = qw(Util.tt2 Form.tt2 Menu.tt2 Content.tt2 General.tt2);
		my @modules = grep {
			!($_ ~~ [@early, 'Page.tt2'])
		} map {
			basename($_)
		} glob($BasePath . '/template/*.tt2');
		foreach my $path (qw(Entity)) {
			push @modules, map {
				$path . '/' . basename($_)
			} glob($BasePath . '/template/' . $path . '/*.tt2');
		}
		logDebug("Path [%s]", $BasePath . '/template');
		logDebug("Early   module: [%s]", $_) foreach @early;
		logDebug("Regular module: [%s]", $_) foreach @modules;
		my %cfg = (
			INCLUDE_PATH	=> [ $BasePath . '/template', '/home/tom/dev/EntityModel/template' ],
			PRE_PROCESS	=> [ @early, @modules ],
			INTERPOLATE	=> 0,
			ABSOLUTE	=> 0,
			RELATIVE	=> 0,
			RECURSION	=> 1,
			AUTO_RESET	=> 0,
			STAT_TTL	=> 5,
			COMPILE_DIR	=> '/tmp/ttc', # $BasePath . '/ttc',
			# COMPILE_DIR	=> undef,
			CACHE_SIZE	=> 4096,
			PRE_DEFINE	=> {
#				cfg		=> \%EntityModel::Config::Current,
#				imageHost	=> 'http://' . EntityModel::Config::ImageHost,
#				scriptHost	=> 'http://' . EntityModel::Config::ScriptHost,
			},
			FILTERS		=> {
				longDate	=> [
					sub {
						my ($context, @args) = @_;
						return sub {
							return longDate(shift, @args);
						}
					}, 1
				],
				shortDate	=> [
					sub {
						my ($context, @args) = @_;
						return sub {
							return shortDate(shift, @args);
						}
					}, 1
				],
				ymdDate	=> [
					sub {
						my ($context, @args) = @_;
						return sub {
							return ymdDate(shift, @args);
						}
					}, 1
				],
				tidyYMD	=> [
					sub {
						my ($context, @args) = @_;
						return sub {
							return tidyYMD(shift, @args);
						}
					}, 1
				],
				fromNow	=> [
					sub {
						my ($context, @args) = @_;
						return sub {
							return fromNow(shift, @args);
						}
					}, 1
				],
				trackDuration => [
					sub {
						my ($context, @args) = @_;
						return sub {
							return trackDuration(shift, @args);
						}
					}, 1
				],
			},
			PLUGINS		=> {
				calendar => 'EntityModel::Template::Plugin::Calendar'
			}
		);
		#$cfg{CONTEXT} = new Template::Timer(%cfg) if EntityModel::Config::Debug;
		my $tmpl = Template->new(%cfg)
			or die Template->error;
		$self->{ template } = $tmpl;
		$templateCache = $tmpl;
	}
	return $self->{ template };
}

sub mergeData {
	my ($self, $origData) = @_;
	my %data = %{$self->{data}};
	foreach my $k (keys %$origData) {
		$data{$k} = $origData->{$k};
	}
	return \%data;
}

=head2 asText

Return template output as text.

=cut

sub asText {
	my ($self, $template, $newData) = @_;
	my $data = $self->mergeData($newData);
	my $output;
	my $tt = $self->template;
	$tt->process($template, $data, \$output) || die 'Failed template: ' . $tt->error;
	return $output;
}

=head2 processHTML

Process HTML data.

=cut

sub processHTML {
	my ($self, $template, $newData) = @_;
	my $data = $self->mergeData($newData);

	my $tt = $self->template;
	my $output;
	$tt->process($template, $data, \$output) || die 'Failed template: ' . $tt->error;
	if(0) {
		my $origSize = length($output);
		$output =~ s/<!--(.*?)-->//g;
		my $tidy = HTML::Tidy->new({
			tidy_mark		=> 0,
			'preserve-entities'	=> 1,
			wrap			=> 160,
			'char-encoding'		=> 'utf8',
			indent			=> 0
		});
		$output = $tidy->clean($output);
		my $finalSize = length($output);
		logDebug("From %d to %d: %3.2f%%", $origSize, $finalSize, (100.0 * $finalSize/$origSize));
	}
	return $output;
}

=head2 output

Generate output via Apache2 print.

=cut

sub output {
	my ($self, $template, $newData, $r) = @_;
	my $data = $self->mergeData($newData);

	logInfo("Output");
	my $output = $self->processHTML($template, $data);
	if($r) {
		$r->content_type('text/html') if $r;
		$r->no_cache(1);
		$r->setLifetime(0);
		$r->print($output);
	} else {
		print $output;
	}
}

=head2 error

Handle any TT2 error messages.

=cut

sub error {
	my $self = shift;
	return $self->template->error;
}

sub addData {
	my ($self, $data) = @_;
	foreach (keys %$data) {
		$self->{data}->{ $_ } = $data->{$_};
	}
	return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.