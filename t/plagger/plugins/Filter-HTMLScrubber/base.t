use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected_with_capture;

__END__

=== Loading Filter::HTMLScrubber
--- input config
plugins:
  - module: Filter::HTMLScrubber
--- expected
ok 1, $block->name;

=== Simple test
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo Bar
      entry:
        - title: Nasty
          body: Foo <style>bar</style>
  - module: Filter::HTMLScrubber
--- expected
unlike $context->update->feeds->[0]->entries->[0]->body, qr!<style>bar</style>!

=== Don't scrub non-HTML
--- input config
global:
  log:
    level: debug
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo Bar
      entry:
        - title: Nasty
          body: This is not HTML.
  - module: Filter::HTMLScrubber
--- expected
unlike $warnings, qr/Scrubbing/;

===
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/feedburner.xml
  - module: Filter::HTMLScrubber
    config:
      default_deny: 1
      allow:
        - p
        - br
        - div
      rules:
        img:
--- expected
unlike $context->update->feeds->[0]->entries->[0]->summary, qr/img/;
unlike $context->update->feeds->[0]->entries->[0]->body, qr/img/;

