# author: Tatsuhiko Miyagawa
sub init {
    my $self = shift;
    $self->{handle} = 'channel/watch/\d+';
}


sub find {
    my ($self, $args) = @_;
    my $uri = URI->new($args->{url});
    my($video_id) = $uri =~ m!/channel/watch/(\d+)!
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://www.woopie.jp/swf/ChannelPlayer-embed480.swf?channel_id=9371");
    $enclosure->type('application/x-shockwave-flash');
    return $enclosure;
}

sub upgrade {
    my($self, $args) = @_;

    my $enclosure = $args->{enclosure};
    return unless $enclosure->type eq 'application/x-shockwave-flash';

    my $uri = URI->new($enclosure->url);
    unless ($uri->query_param('autostart')) {
        $enclosure->url($enclosure->url . "&autostart=1");
    }

    $enclosure->width(480);
    $enclosure->height(400);
}
