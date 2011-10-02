use strict;
use warnings;

use Test::More tests => 18;
use_ok('EntityModel::Query');
use_ok('EntityModel::Model');

use_ok('EntityModel::Definition');
use_ok('EntityModel::Definition::XML');
use_ok('EntityModel::Definition::JSON');
use_ok('EntityModel::Definition::Perl');

use_ok('EntityModel::Support');
use_ok('EntityModel::Support::Perl');
use_ok('EntityModel::Support::Javascript');
use_ok('EntityModel::Support::CPP');

use_ok('EntityModel::Storage');
use_ok('EntityModel::Storage::Perl');

use_ok('EntityModel::Cache');
use_ok('EntityModel::Cache::Perl');

use_ok('EntityModel::Plugin');

use_ok('EntityModel::Template');

use_ok('EntityModel');

use_ok('EntityModel::App');
