use strict;
use FindBin;

use t::TestPlagger;

plan tests => 5;
run_eval_expected;

__END__

=== swf
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/thesocialwebtv.xml
        - file://$t::TestPlagger::BaseDirURI/t/samples/viddler.html
  - module: Aggregator::Simple
  - module: CustomFeed::FindLinks
    config:
      follow_selector: a[rel="enclosure"]
  - module: Filter::FindEnclosures
--- expected
is $context->update->feeds->[0]->entries->[0]->primary_enclosure->url, "http://www.viddler.com/player/962671ef/";
is $context->update->feeds->[0]->entries->[0]->primary_enclosure->type, "application/x-shockwave-flash";
# like $context->update->feeds->[0]->entries->[0]->thumbnail->{url}, qr/thumbnail.action/;

is $context->update->feeds->[1]->entries->[0]->primary_enclosure->url, "http://www.viddler.com/player/962671ef/";
is $context->update->feeds->[1]->entries->[0]->primary_enclosure->width, 545;
like $context->update->feeds->[1]->entries->[0]->thumbnail->{url}, qr/thumbnail.action/;

