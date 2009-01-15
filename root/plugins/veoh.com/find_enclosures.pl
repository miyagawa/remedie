# author: Tatsuhiko Miyagawa
# TODO veoh rss feed has .mp4 file enclosures but it doesn't work with Flash player
sub init {
    my $self = shift;
    $self->{handle} = "videoDetails\.html|/videos/";
}


sub find {
    my ($self, $args) = @_;

    my $uri = URI->new($args->{url});

    my $id = $uri->query_param('v') || ($uri->path =~ m!/videos/(\w+)!)[0]
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://www.veoh.com/veohplayer.swf?permalinkId=$id&id=&player=videodetailsembedded&videoAutoPlay=1");
    $enclosure->type("application/x-shockwave-flash");
    return $enclosure;
}

# TODO use Veoh API
# sub upgrade {}
