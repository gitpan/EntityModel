use strict;
use warnings;

use Test::More tests => 5;
use EntityModel::Deferred;

my $d = new_ok('EntityModel::Deferred' => [ ]);
ok($d->queue_callback('ready', sub {
	my $defer = shift;
	isa_ok($defer, 'EntityModel::Deferred');
	is($defer->value, 15, 'value is correct');
}), 'queue the callback');
ok($d->provide_value(15), 'provide a value');

