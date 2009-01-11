use strict;
use t::TestPlagger;

test_requires_network 'mininova.org';
plan 'no_plan';
run_eval_expected;

__END__

===
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://www.mininova.org/search/?search=test
        - http://www.mininova.org/search/test/1
  - module: Discovery::Sites

--- expected
is $context->subscription->feeds->[0]->url, "http://www.mininova.org/rss/test";
is $context->subscription->feeds->[1]->url, "http://www.mininova.org/rss/test/1";
