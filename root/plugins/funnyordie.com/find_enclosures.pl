# author: Tatsuhiko Miyagawa
sub init {
    my $self = shift;
    $self->{handle} = 'videos/\w+/';
}


sub find {
    my ($self, $args) = @_;
    my $uri = URI->new($args->{url});
    my $video_id = ($uri->path =~ m!^/videos/(\w_)!)[0]
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://player.ordienetworks.com/flash/fodplayer.swf?key=$video_id");
    $enclosure->type('application/x-shockwave-flash');
    return $enclosure;
}

sub upgrade {
    my($self, $args) = @_;

    my $enclosure = $args->{enclosure};
    return unless $enclosure->type eq 'application/x-shockwave-flash';

    # Do not use query_param because their RSS feed is broken (fodplayers.swf&key=...)
    my($video_id) = $enclosure->url =~ /key=(\w+)/
        or return;

    # set thumbnail if it's not there
    unless ($enclosure->thumbnail) {
        $enclosure->thumbnail({
            url => "http://assets1.ordienetworks.com/tmbs/$video_id/medium_11.jpg",
            width => 120, height => 90,
        });
    }

    $enclosure->url("http://player.ordienetworks.com/flash/fodplayer.swf?autostart=true&key=$video_id");
}

