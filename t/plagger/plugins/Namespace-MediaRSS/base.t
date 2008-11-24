use strict;
use FindBin;

use t::TestPlagger;

plan tests => 24;
run_eval_expected;

__END__

=== Media RSS
--- input config 
global:
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/monkey.rss
        - file://$t::TestPlagger::BaseDirURI/t/samples/googlevideo.xml
        - file://$t::TestPlagger::BaseDirURI/t/samples/flickr_new.xml
        - file://$t::TestPlagger::BaseDirURI/t/samples/tekzilla.xml
        - file://$t::TestPlagger::BaseDirURI/t/samples/hulu.xml
        - file://$t::TestPlagger::BaseDirURI/t/samples/webbalert.xml
        - file://$t::TestPlagger::BaseDirURI/t/samples/bliptv.xml
--- expected
my @feeds = $context->update->feeds;

is $feeds[0]->entries->[0]->enclosures->[0]->url, 'http://youtube.com/v/MgldehkjK5k.swf';
is $feeds[0]->entries->[0]->enclosures->[0]->type, 'application/x-shockwave-flash';
is $feeds[0]->entries->[0]->icon->{url}, 'http://sjl-static4.sjl.youtube.com/vi/MgldehkjK5k/2.jpg';

is $feeds[1]->entries->[0]->enclosures->[0]->type, 'video/mp4';
is $feeds[1]->entries->[0]->enclosures->[1]->type, 'video/x-flv';
is $feeds[1]->entries->[0]->icon->{url}, 'http://video.google.com/ThumbnailServer?app=vss&contentid=ac22092b58659308&second=5&itag=w320&urlcreated=1148908032&sigh=oxDLuV7bChBhYFMFSFamVpkIHHE';

is $feeds[2]->entries->[0]->enclosures->[0]->type, 'image/jpeg';
is $feeds[2]->entries->[0]->enclosures->[0]->url, 'http://static.flickr.com/109/313831333_60eb5e65b5_m.jpg';

# tekzilla
is $feeds[3]->entries->[0]->enclosures->[0]->length, 666811687;
is $feeds[3]->entries->[0]->enclosures->[0]->type, "video/mp4";
like $feeds[3]->entries->[0]->enclosures->[0]->url, qr/hd.h264.mp4/;
like $feeds[3]->entries->[0]->thumbnail->{url}, qr/thumb\.jpg/;
is $feeds[3]->entries->[0]->thumbnail->{width}, 100;
is $feeds[3]->entries->[0]->thumbnail->{height}, 100;

# Hulu
like $feeds[4]->entries->[0]->enclosure->url, qr/embed/;
is $feeds[4]->entries->[0]->enclosure->type, "application/x-shockwave-flash";
is $feeds[4]->entries->[0]->enclosure->width, "512";
like $feeds[4]->entries->[0]->thumbnail->{url}, qr/thumbnails.hulu.com/;
is $feeds[4]->entries->[0]->thumbnail->{width}, 145;

# Webbalert
like $feeds[5]->image->{url}, qr/webbalert-itunes/;
like $feeds[5]->entries->[0]->enclosure->url, qr/\.mp4/;
is $feeds[5]->entries->[0]->enclosure->type, "video/mp4";
like $feeds[5]->entries->[0]->thumbnail->{url}, qr/cdn.episodic.com/;

# Blip.tv
like $feeds[6]->entries->[0]->enclosure->type, qr/quicktime/;

