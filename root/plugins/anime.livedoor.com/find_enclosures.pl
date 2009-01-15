sub init {
    my $self = shift;
    $self->{handle} = "movie";
}


sub find {
    my ($self, $args) = @_;
    my $uri = URI->new($args->{url});
    my $id = ($uri->path =~ m!^/movie/([\w\-]+)!)[0]
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://image.anime.livedoor.com/swf/$id.flv");
    $enclosure->type('video/x-flv');
    return $enclosure;
}


