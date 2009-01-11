use strict;
use t::TestPlagger;

test_requires_network 'www.nhk-ep.co.jp:80';
plan 'no_plan';
run_eval_expected;

__END__

===
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - url: http://www.nhk-ep.co.jp/netstar/yuzu_movie_dec.html
  - module: Aggregator::Simple
  - module: CustomFeed::FindLinks

--- expected
is $context->update->feeds->[0]->entries->[0]->link, 'http://www.nhk-ep.co.jp/netstar/yuzu_mov_dec01.html';
