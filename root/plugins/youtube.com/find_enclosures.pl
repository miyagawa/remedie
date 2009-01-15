# author: Tatsuhiko Miyagawa
# 1. find    -> embed SWF from video_id
# 2. upgrade -> Add JS params like fmt=18, check if it's HD and set fmt=22

sub init {
    my $self = shift;
    $self->{handle} = ".";
}


sub find {
    my ($self, $args) = @_;
    my $uri = URI->new($args->{url});
    my $video_id = ($uri =~ m!/v/([\w\-]+)!)[0] || $uri->query_param('v') or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://youtube.com/v/$video_id.swf");
    $enclosure->type('application/x-shockwave-flash');
    return $enclosure;
}

sub swf_url {
    my $self = shift;
    my($video_id, $fmt) = @_;
    return "http://youtube.com/v/$video_id&fs=1&autoplay=1&enablejsapi=1&ap=%2526fmt%3D$fmt";
}

sub upgrade {
    my($self, $args) = @_;

    my $enclosure = $args->{enclosure};

    return unless $enclosure->type eq 'application/x-shockwave-flash';
    my($video_id) = $enclosure->url =~ m!/v/([\w\-]+)!
        or return;

    # set thumbnail if it's not there
    unless ($enclosure->thumbnail) {
        $enclosure->thumbnail({
            url => "http://img.youtube.com/vi/$video_id/default.jpg",
            width => 130, height => 97,
        });
    }

    # scrape the page to check if it has HD
    # FIXME content should be shared with needs_content
    my $content = Plagger->context->current_plugin->fetch_content("http://www.youtube.com/watch?v=$video_id&fmt=22");
    if ($content =~ m!"fmt_map":\s*"22/!) {
        Plagger->context->log(info => "$video_id has HD version :)");
        $enclosure->url($self->swf_url($video_id, 22));
        $enclosure->width(1280);
        $enclosure->height(720);
    } else {
        Plagger->context->log(info => "$video_id has no HD version :/");
        $enclosure->url($self->swf_url($video_id, 18));
        $enclosure->width(704);
        $enclosure->height(396);
    }
}

