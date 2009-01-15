# author: Tatsuhiko Miyagawa
# 1. find    -> embed SWF from clip_id
# 2. upgrade -> Set autoplay

sub init {
    my $self = shift;
    $self->{handle} = ".";
}


sub find {
    my ($self, $args) = @_;
    my $uri = URI->new($args->{url});
    my($video_id) = $uri->path =~ m!^/(\d+)! or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://vimeo.com/moogaloop.swf?clip_id=$video_id");
    $enclosure->type('application/x-shockwave-flash');
    return $enclosure;
}

sub upgrade {
    my($self, $args) = @_;

    my $uri = URI->new($args->{enclosure}->url);
    return unless $uri->path eq '/moogaloop.swf';

    $uri->query_param(autoplay => 1);
    $args->{enclosure}->url($uri->as_string);

    # There should be a way to detect this, but for now we could assume it's 16x9 video
    $args->{enclosure}->width(1024);
    $args->{enclosure}->height(576);
}

