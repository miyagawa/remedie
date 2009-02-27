sub init {
    my $self = shift;
    $self->{handle} = '/video\?id=\d+';
}


sub find {
    my ($self, $args) = @_;
    my ($id) = $args->{entry}->link =~ m!id=(\d+)!
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://clipcast.jp/player/player.swf?id=$id&auto=true&v=2");
    $enclosure->width(425);
    $enclosure->height(400);
    $enclosure->type('application/x-shockwave-flash');
    $enclosure->thumbnail({ url => "http://convertor.clipcast.jp/mediastudio/player/thumbnail/index.php?id=$id&s=5&size=l", width => 320, height => 240 });
    return $enclosure;
}
