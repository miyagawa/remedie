# http://www.47news.jp/movie/
# http://www.47news.jp/video/
sub init {
    my $self = shift;
    $self->{handle} = '/post_\d+';
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    my $link = $args->{entry}->link;

    my ($url, $width, $height,$thumbnail);
    if($link =~ m!/movie/!) {
        $url = "http://www.47news.jp/movie/flv_player640x480.swf?SURL=$link";
        $width = 435;
        $height = 360;
        ($thumbnail) = $args->{content} =~ m!$link.*?src="(.*?_video\.jpg)"!;
    }
    else {
        my ($id) = $args->{content} =~ m!$link.*?(\d+_video)!
            or return;
        $url = "http://www.47news.jp/video/clips/$id.flv";
        $width = 640;
        $height = 480;
        $thumbnail = "http://www.47news.jp/video/clips/$id.jpg";
    }

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($url);
    $enclosure->type("application/x-shockwave-flash");
    $enclosure->width($width);
    $enclosure->height($height);
    $enclosure->thumbnail({ url => $thumbnail }) if $thumbnail;

    return $enclosure;
}
