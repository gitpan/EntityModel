use strict;
use warnings FATAL => 'all';
use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

{
# Not going to get very far if we haven't pulled this in already
use Pod::Simple;
no warnings 'redefine';
no strict 'refs';

# Which module names we've seen already
my %SEEN_MODULES;

# Whether we're already in a head1 section
my $in_head1;

# Whether we're in a =head1 NAME
my $name_section;

# Current element name
my $element;

# Want to pick up on element start so we can flag our =head1 sections, and reset at the start of the document
*{'Pod::Simple::_handle_element_start'} = sub {
	my ($parser, $element_name, $attr_hash_r) = @_;
	if($element_name eq 'Document') {
		undef $name_section;
		undef $element;
		undef $in_head1;
	}
	$element = $element_name;
	$in_head1 = ($element_name eq 'head1');
};

# Does two things - sets the flag when we're in NAME, and applies the duplicate check for the actual name text
*{'Pod::Simple::_handle_text'} = sub {
	my($parser, $text) = @_;
	$name_section = ($text eq 'NAME') if $element eq 'head1';
	return unless $name_section && $element eq 'Para';
	my ($module) = $text =~ /^(\S+)/;
	$parser->whine("Duplicate entry for $module") if $SEEN_MODULES{$module}++;
};

}

all_pod_files_ok();
