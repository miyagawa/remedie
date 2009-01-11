use lib "extlib";
use strict;
use t::TestPlagger;

test_requires_network 'www.jp.playstation.com';
plan 'no_plan';
run_eval_expected;

__END__

===
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://www.jp.playstation.com/psworld/movie/
  - module: CustomFeed::Scraper

--- expected
like $context->subscription->feeds->[0]->entries->[0]->primary_enclosure->{url}, qr/asx/;
like $context->subscription->feeds->[0]->entries->[0]->link, qr/http/;

