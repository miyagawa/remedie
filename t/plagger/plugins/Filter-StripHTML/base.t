use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected_with_capture;

__END__

===
--- input config
plugins:
  - module: Filter::StripHTML
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
          body: <p>Foo <a href="bar">bar</a></p>
  - module: Filter::StripHTML
--- expected
like $context->update->feeds->[0]->entries->[0]->body, qr!Foo bar!

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
  - module: Filter::StripHTML
--- expected
unlike $warnings, qr/Stripping/;

===
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/feedburner.xml
  - module: Filter::StripHTML
--- expected
unlike $context->update->feeds->[0]->entries->[0]->summary, qr/img/;
unlike $context->update->feeds->[0]->entries->[0]->body, qr/img/;
