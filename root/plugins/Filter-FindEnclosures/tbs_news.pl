# author: Tatsuhiko Miyagawa

sub handle {
    my ($self, $url) = @_;
    $url =~ qr!http://news.tbs.co.jp/newseye/!;
}

sub needs_content { 0 }

sub find {
    my ($self, $args) = @_;

    $args->{url} =~ m!http://news.tbs.co.jp/newseye/tbs_newseye(\d+)\.html!
        or return;

    my $id = $1;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://news.tbs.co.jp/flv/news${id}_27.flv");
    $enclosure->type("video/x-flv");
    $enclosure->thumbnail({ url => "http://news.tbs.co.jp/jpg/news${id}_6.jpg" });
    return $enclosure;
}
