# http://cancam.tv/content/models_room/0809naoko/flv/0809naoko.flv
# author: Tatsuhiko Miyagawa

sub handle {
    my ($self, $url) = @_;
    $url =~ qr!http://cancam.tv/content/models_room/!;
}

sub needs_content { 0 }

sub find {
    my ($self, $args) = @_;
    my $id = $args->{url} =~ qr!models_room/(\w+)! ? $1 : ""
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://cancam.tv/content/models_room/$id/flv/$id.flv");
    $enclosure->type('video/x-flv');
    return $enclosure;
}
