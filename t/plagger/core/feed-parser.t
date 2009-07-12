use utf8;
use t::TestPlagger;
use Plagger::UserAgent;
use Plagger::FeedParser;

test_requires_network;
plan tests => 1 * blocks;

filters { input => 'chomp', expected => 'chomp' };

run {
    my $block = shift;
    my $ua   = Plagger::UserAgent->new;
    my $feed_uri = Plagger::FeedParser->discover($ua->fetch($block->input));
    is $feed_uri, $block->expected, $block->name;
}

__END__

=== Straight Feed URL
--- input
http://remediecode.org/atom.xml
--- expected
http://remediecode.org/atom.xml

=== Auto-Discovery
--- input
http://blog.bulknews.net/mt/
--- expected
http://blog.bulknews.net/mt/index.rdf



