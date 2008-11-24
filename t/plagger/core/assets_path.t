use strict;
use t::TestPlagger;

plan 'no_plan';
run_eval_expected_with_capture;

package Plagger::Plugin::Test::AssetsPath;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $self->log(error => "assets_path is " . $self->assets_dir);
}

package main;

__END__

=== Test global:assets_path
--- input config
plugins:
  - module: Test::AssetsPath
--- expected
like $warnings, qr!plugins[/\\]Test-AssetsPath!;

=== Test plugin:assets_path
--- input config
global:
  assets_path: /tmp/assets
plugins:
  - module: Test::AssetsPath
    config:
      assets_path: $t::TestPlagger::BaseDir/t/samples
--- expected
unlike $warnings, qr!/tmp/assets!;
like $warnings, qr!assets_path is .*t/samples!m;
