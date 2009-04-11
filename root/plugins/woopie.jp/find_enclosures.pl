# author: Tatsuhiko Miyagawa
sub init {
    my $self = shift;
    $self->{handle} = '/video/watch/[0-9a-f]+';
}


sub find {
    my ($self, $args) = @_;
    my $uri = URI->new($args->{url});
    my($video_id) = $uri =~ m!/video/watch/([0-9a-f]+)!
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://www.woopie.jp/swf/ChannelPlayer-embed480.swf?video_id=$video_id");
    $enclosure->type('application/x-shockwave-flash');
    return $enclosure;
}

sub upgrade {
    my($self, $args) = @_;

    my $enclosure = $args->{enclosure};
    return unless $enclosure->type eq 'application/x-shockwave-flash';

    my $uri = URI->new($enclosure->url);
    unless ($uri->query_param('autoplay')) {
        $uri->query_param(autoplay => 1);
        $enclosure->url($uri->as_string);
    }

    $enclosure->width(480);
    $enclosure->height(400);
}
