# author: Tatsuhiko Miyagawa
# feed: http://ugomemo.hatena.ne.jp/rss
sub init {
    my $self = shift;
    $self->{handle} = "/movie/";
}


sub find {
    my ($self, $args) = @_;
    my $uri = URI->new($args->{url});
    my($did, $file) = $uri->path =~ m!^/(\w+)\@DSi/movie/(\w+)!
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://ugomemo.hatena.ne.jp/js/ugoplayer_s.swf?did=$did&file=$file");
    $enclosure->type('application/x-shockwave-flash');
    $enclosure->width(279);
    $enclosure->height(240);
    $enclosure->thumbnail({ url => "http://image.ugomemo.hatena.ne.jp/thumbnail/${did}/${file}_as.gif" });
    return $enclosure;
}
