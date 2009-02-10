sub init {
    my $self = shift;
    $self->{handle} = '/movies/movie/[^/]+/';
}

sub find {
    my ($self, $args) = @_;

    my($id) = $args->{url} =~ m!/movies/movie/([^/]+)/!
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://mooom.jp/P320x240.swf?m=$id");
    $enclosure->width(320);
    $enclosure->height(270);
    $enclosure->type('application/x-shockwave-flash');
    return $enclosure;
}
