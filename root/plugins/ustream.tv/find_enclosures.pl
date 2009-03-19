sub init {
    my $self = shift;
    $self->{handle} = '/recorded/\d+';
}

sub find {
    my($self, $args) = @_;

    my $id = (URI->new($args->{url})->path =~ m!^/recorded/(\d+)!)[0]
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://www.ustream.tv/flash/video/$id");
    $enclosure->type("application/x-shockwave-flash");
    $enclosure->width(400);
    $enclosure->height(320);

    return $enclosure;
}
