use strict;
use t::TestPlagger;

test_requires_network;
plan 'no_plan';
run_eval_expected;

__END__

=== 301 redirects
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://revision3.com/tekzilla/feed/quicktime-large
--- expected
ok $context->update->feeds->[0]->title;
is $context->update->feeds->[0]->url, "http://revision3.com/tekzilla/feed/quicktime-large/";
