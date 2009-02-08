# author: Yusuke Wada aka yusukebe

sub init {
    my $self = shift;
    $self->{handle} = "/watch/";
}

sub find {
    my ($self, $args) = @_;
    my $uri = URI->new($args->{url});
    my($video_id) = $uri->path =~ m!/watch/(\d+)!
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://www.guba.com/f/root.swf?bid=$video_id&isEmbeddedPlayer=false");
    $enclosure->type('application/x-shockwave-flash');
    return $enclosure;
}
