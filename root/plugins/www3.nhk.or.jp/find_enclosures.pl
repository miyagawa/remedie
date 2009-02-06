# author: Tatsuhiko Miyagawa
sub init {
    my $self = shift;
    $self->{handle} = '/news/[kt]\d+.html';
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    # find the key for this news
    my($asx_url, $key) = $args->{content} =~ m!wmvHigh = "(.*/cgibin/((.*?)_(.*?)_(.*?))(?:_(.*?))?_mh.cgi)"!
        or return;

    # ad-hoc pattern to find articles with non-video
    return if $key =~ /K10099999999/;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("rtmp://flv.nhk.or.jp/ondemand/flv/news/$key");
    $enclosure->type("video/x-flv");

    if ($args->{content} =~ m!switchPlayer.*?src="(K[\d_]+\.jpg)" width="(\d+)" height="(\d+)"!) {
        $enclosure->thumbnail({ url => "http://www3.nhk.or.jp/news/$1", width => $2, height => $3 });
    }

    return $enclosure;
}
