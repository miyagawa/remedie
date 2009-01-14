# author: Tatsuhiko Miyagawa
sub init {
    my $self = shift;
    $self->{handle} = '2001-1_53-\d+\.html';
}

sub find {
    my ($self, $args) = @_;
    my $uri = URI->new($args->{url});
    my $video_id = ($uri =~ m!/2001-1_53-(\d+)\.html!)[0]
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://www.cnet.com/av/video/flv/newPlayers/universal.swf?playerType=embedded&value=$video_id");
    $enclosure->type('application/x-shockwave-flash');
    $enclosure->width(335);
    $enclosure->height(360);
    return $enclosure;
}

