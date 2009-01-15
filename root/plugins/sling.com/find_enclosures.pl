# author: Yasuhiro Matsumoto

sub init {
    my $self = shift;
    $self->{handle} = "/video/show/.*";
}

sub handle {
    my ($self, $url) = @_;
    $url =~ qr!beta\.sling\.com/video/show/.*!;
}


sub find {
    my ($self, $args) = @_;
    my $uri = URI->new($args->{url});
    my $video_id = ($uri =~ m!/video/show/([^/]+)!)[0];

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://beta.sling.com/v/$video_id");
    $enclosure->type('application/x-shockwave-flash');
    $enclosure->width(448);
    $enclosure->height(280);
    return $enclosure;
}
