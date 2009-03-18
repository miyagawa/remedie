use URI::QueryParam;
sub init {
    my $self = shift;
    $self->{handle} = '/doga/viewvideo.jspx\?Movie=';
}

sub find {
    my($self, $args) = @_;

    my $path = URI->new($args->{url})->query_param('Movie') or return;
    (my $id = $path) =~ s/\.flv$//;
    (my $img = $id) =~ s!^\d+/!!;

    my $uri = URI->new("http://doga.nhk.or.jp/doga/pluginplayerv1_strm.swf");
    $uri->query_form(
        image => "http://doga.nhk.or.jp/doga/img/userimg/${img}_1.jpg",
        streamer => "rtmp://dogaflv.nhk.or.jp/dogaflv/",
        file => "userdir/$id.flv",
        skin => "http://doga.nhk.or.jp/doga/playerskinv1_swift.swf",
        logo => "http://doga.nhk.or.jp/doga/img/wtrmrg.png",
        autostart => 1,
    );

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($uri);
    $enclosure->type("application/x-shockwave-flash");
    $enclosure->width(496);
    $enclosure->height(404);

    return $enclosure;
}
