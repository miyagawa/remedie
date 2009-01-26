use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

===
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/filenames.xml
  - module: Filter::MediaFilename
--- expected
is $context->update->feeds->[0]->entries->[0]->title, "Test S03E10";
is $context->update->feeds->[0]->entries->[0]->summary, "Test.S03E10.720p.HDTV.mp4";
ok $context->update->feeds->[0]->entries->[0]->has_tag('720p');
is $context->update->feeds->[0]->entries->[1]->title, "Foo - 02";
ok $context->update->feeds->[0]->entries->[1]->has_tag('1280x720');
is $context->update->feeds->[0]->entries->[2]->title, "\x{30c6}\x{30b9}\x{30c8}";

