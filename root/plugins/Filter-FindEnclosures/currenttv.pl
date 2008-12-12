# author: Tatsuhiko Miyagawa

sub init {
    my $self = shift;
    $self->{domain} = "current.com";
    $self->{handle} = '/items/\d+/';
}

sub needs_content { 0 }

sub find {
    my ($self, $args) = @_;
    my $uri = URI->new($args->{url});
    my($video_id) = $uri->path =~ m!^/items/(\d+)!
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://current.com/e/${video_id}/en_US");
    $enclosure->type('application/x-shockwave-flash');
    $enclosure->width(400);
    $enclosure->height(400);
    return $enclosure;
}
