use strict;
use Test::More tests => 2;
use FindBin;

use Plagger;

my $config = <<CONFIG;
global:
  log:
    level: error
  cache:
    expires: 2 seconds
plugins:
  - module: Test::Cache
CONFIG

diag("This test sleeps for 3 seconds for cache expiration");
Plagger->bootstrap(config => YAML::Load($config));
sleep 3;
Plagger->bootstrap(config => YAML::Load($config));

package Plagger::Plugin::Test::Cache;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'plugin.init' => \&test,
    );
}

my $set;

sub test {
    my($self, $context, $args) = @_;
    if (! $set++) {
        $self->cache->set("foo" => "bar");
        ::is $self->cache->get("foo"), "bar";
    } else {
        ::isnt $self->cache->get("foo"), "bar";
    }
}

