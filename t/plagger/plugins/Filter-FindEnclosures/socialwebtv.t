use strict;
use FindBin;

use t::TestPlagger;

plan tests => 2;
run_eval_expected;

__END__

=== swf
--- input config 
global:
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/thesocialwebtv.xml
  - module: Aggregator::Simple
  - module: Bundle::Remedie
--- expected
is $context->update->feeds->[0]->entries->[0]->primary_enclosure->url, "http://www.viddler.com/player/962671ef/";
is $context->update->feeds->[0]->entries->[0]->primary_enclosure->type, "application/x-shockwave-flash";
