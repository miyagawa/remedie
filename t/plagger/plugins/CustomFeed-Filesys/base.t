use strict;
use t::TestPlagger;
use lib "extlib";

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Local feed
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/tekzilla.xml
  - module: CustomFeed::Filesys
--- expected
is $context->update->feeds->[0]->title, "Tekzilla (HD Quicktime)";

===
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/folder
  - module: CustomFeed::Filesys
    config:
      extensions:
        - mp3
--- expected
is $context->update->feeds->[0]->title, "folder";
is $context->update->feeds->[0]->count, 1;
is $context->update->feeds->[0]->entries->[0]->title, "foo.mp3";
