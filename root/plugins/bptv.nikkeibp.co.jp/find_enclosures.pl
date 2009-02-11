sub init {
    my $self = shift;
    $self->{handle} = '/article/\d+/\d+.html';
}

sub find {
    my($self, $args) = @_;

    my($url) = $args->{entry}->link =~ m!^(.*)\.html!
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("$url.asx");
    $enclosure->type("video/x-ms-asx");
    $enclosure->width(320);
    $enclosure->height(305);
    return $enclosure;
}

