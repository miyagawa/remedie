# author: Tatsuhiko Miyagawa
sub init {
    my $self = shift;
    $self->{domain} = "www.nhk-ep.co.jp";
    $self->{handle} = "/netstar/.*_mov_";
}

sub needs_content { 0 }

sub find {
    my ($self, $args) = @_;

    warn $args->{url};
    $args->{url} =~ qr!http://www.nhk-ep.co.jp/netstar/(\w+)_mov_(\w+\d+)\.html!
        or return;
    my($name, $id) = ($1, $2);

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://www.nhk-ep.co.jp/netstar/flv/${name}_$id.flv");
    $enclosure->type("video/x-flv");
    $enclosure->thumbnail({ url => "http://www.nhk-ep.co.jp/netstar/img/mov_thumb_${name}_${id}.jpg" });
    return $enclosure;
}
