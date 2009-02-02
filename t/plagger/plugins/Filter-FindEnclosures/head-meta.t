use strict;
use FindBin;
use t::TestPlagger;

test_requires_network 'video.yahoo.com:80';
plan tests => 3;
run_eval_expected;

__END__

=== Test 1
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Test
      link: http://example.com/
      entry:
        - title: Test 1
          link: http://video.yahoo.com/watch/4403981/11812238
  - module: Filter::FindEnclosures
--- expected
like $context->update->feeds->[0]->entries->[0]->enclosure->url, qr|http://d.yimg.com/static.video.yahoo.com/yep/YV_YEP.swf|;
is $context->update->feeds->[0]->entries->[0]->enclosure->width, 576;
is $context->update->feeds->[0]->entries->[0]->enclosure->thumbnail->{url}, "http://us.i1.yimg.com/us.yimg.com/p/i/bcst/videosearch/899/79387316.jpeg";

