# author: Tatsuhiko Miyagawa
sub init {
    my $self = shift;
    $self->{handle} = "/newseye/";
}


sub find {
    my ($self, $args) = @_;

    $args->{url} =~ m!/newseye/tbs_newseye(\d+)\.html!
        or return;

    my $id = $1;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://news.tbs.co.jp/flv/news${id}_27.flv");
    $enclosure->type("video/x-ms-asf");
    $enclosure->thumbnail({ url => "http://news.tbs.co.jp/jpg/news${id}_6.jpg" });
    return $enclosure;
}
