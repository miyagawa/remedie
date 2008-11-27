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
