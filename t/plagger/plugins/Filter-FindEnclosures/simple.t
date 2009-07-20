use strict;
use FindBin;
use t::TestPlagger;

plan tests => 1 * blocks;
run_eval_expected;

__END__

===
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Test
      link: http://example.com/
      entry:
        - title: Test 1
          link: http://bulknews.typepad.com/
          body: |
            Here's a link to MP3. <a href="foo.mp3">foo</a>
  - module: Filter::FindEnclosures
--- expected
like $context->update->feeds->[0]->entries->[0]->enclosure->url, qr!http://bulknews.typepad.com/foo.mp3!;

=== 
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Test
      link: http://example.com/
      entry:
        - title: Test 1
          link: http://bulknews.typepad.com/
          body: |
            <a href="foo.xvid" rel="enclosure">foo</a>
  - module: Filter::FindEnclosures
--- expected
like $context->update->feeds->[0]->entries->[0]->enclosure->url, qr!http://bulknews.typepad.com/foo.xvid!;

=== 
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Test
      link: http://example.com/
      entry:
        - link: http://bulknews.typepad.com/
          body: |
            <embed src="foo.mp3"></embed>
  - module: Filter::FindEnclosures
--- expected
like $context->update->feeds->[0]->entries->[0]->enclosure->url, qr!http://bulknews.typepad.com/foo.mp3!;

=== 
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Test
      link: http://example.com/
      entry:
        - link: http://bulknews.typepad.com/
          body: |
            <object><param name="movie" value="http://www.example.com/foo.flv"></object>
  - module: Filter::FindEnclosures
--- expected
like $context->update->feeds->[0]->entries->[0]->enclosure->url, qr!http://www.example.com/foo.flv!;
