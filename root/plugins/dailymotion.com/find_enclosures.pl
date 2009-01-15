# author: Tatsuhiko Miyagawa

sub init {
    my $self = shift;
    $self->{handle} = "/video/";
}


sub find {
    my ($self, $args) = @_;
    my $uri = URI->new($args->{url});
    my($video_id) = $uri->path =~ m!^/video/([a-zA-Z0-9]+)!
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://www.dailymotion.com/swf/$video_id");
    $enclosure->type('application/x-shockwave-flash');
    return $enclosure;
}

sub upgrade {
    my($self, $args) = @_;

    my $enclosure = $args->{enclosure};
    return unless $enclosure->type eq 'application/x-shockwave-flash';

    my($video_id) = $enclosure->url =~ m!/swf/([a-zA-Z0-9]+)!
        or return;

    $enclosure->url("http://www.dailymotion.com/swf/$video_id?autoplay=1&canvas=large");
}

