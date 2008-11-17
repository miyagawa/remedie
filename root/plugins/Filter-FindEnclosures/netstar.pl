# author: Tatsuhiko Miyagawa

sub handle {
    my ($self, $url) = @_;
    $url =~ qr!http://www.nhk-ep.co.jp/netstar/.*_mov_!;
}

sub needs_content { 0 }

sub find {
    my ($self, $args) = @_;
    my($name, $id) = $args->{url} =~ qr!http://www.nhk-ep.co.jp/netstar/(\w+)_mov_(\w+\d+)\.html!;
    return unless $name && $id;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://www.nhk-ep.co.jp/netstar/flv/${name}_$id.flv");
    $enclosure->type("video/x-flv");
    $enclosure->thumbnail({ url => "http://www.nhk-ep.co.jp/netstar/img/mov_thumb_${name}_${id}.jpg" });
    return $enclosure;
}
