# author: Tatsuhiko Miyagawa
# 1. find    -> embed SWF from video_id
# 2. upgrade -> Check if the video is embeddable

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
    my($video_id) = @_;
    return "http://youtube.com/v/$video_id?fs=1&autoplay=1&enablejsapi=1";
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

    # FIXME content should be shared with needs_content
    my $content = $self->parent->fetch_content("http://www.youtube.com/watch?v=$video_id&fmt=22");
    if ($content =~ /Embedding disabled by request/) {
        Plagger->context->log(info => "$video_id disables embeds :/");
        $enclosure->url("http://www.youtube.com/watch?v=$video_id");
        $enclosure->type("text/html");
    } else {
        $enclosure->url($self->swf_url($video_id));
        $enclosure->width(704);
        $enclosure->height(396);
    }
}
