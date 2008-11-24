use strict;
use FindBin;

use t::TestPlagger;

plan tests => 3;
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
        - file://$t::TestPlagger::BaseDirURI/t/samples/tekzilla.xml
        - file://$t::TestPlagger::BaseDirURI/t/samples/webbalert.xml
  - module: Namespace::iTunesDTD
--- expected
my @feeds = $context->update->feeds;

# tekzilla
like $feeds[0]->image->{url}, qr/tekzilla.jpg/;
like $feeds[0]->entries->[0]->summary, qr/Manage All/;

# Webbalert
like $feeds[1]->image->{url}, qr/webbalert-itunes/;

