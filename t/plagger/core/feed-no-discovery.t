use t::TestPlagger;

test_requires_network 'www.fnn-news.com';

plan 'no_plan';
run_eval_expected;

__END__

===
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://www.fnn-news.com/news/headlines/category03.html
  - module: Aggregator::Simple
    config:
      no_discovery: 1
  - module: CustomFeed::FindLinks
--- expected
unlike $context->update->feeds->[0]->entries->[0]->link, qr/chgPage/;


