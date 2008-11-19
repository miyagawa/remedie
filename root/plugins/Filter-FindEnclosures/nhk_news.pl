# author: Tatsuhiko Miyagawa

sub handle {
    my ($self, $url) = @_;
    $url =~ qr!http://www3.nhk.or.jp/news/t\d+.html!;
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    # flv uses rtmp. JW FLV player supports RTMP but needs a hack on the JS side
    $args->{content} =~ m!wmvHigh = "(.*/cgibin/((.*?)_(.*?)_(.*?))_(.*?)_mh.cgi)"!
        or return;
    my $asx_url = $1;
    my $key = $2;
    my $url = $self->find_mms_url($asx_url, $key);

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($url);
    $enclosure->type("video/x-ms-asf");

    if ($args->{content} =~ m!switchPlayer.*?src="(K[\d_]+\.jpg)" width="(\d+)" height="(\d+)"!) {
        $enclosure->thumbnail({ url => "http://www3.nhk.or.jp/news/$1", width => $2, height => $3 });
    }

    return $enclosure;
}

sub find_mms_url {
    my ($self, $asx_url, $key) = @_;

    my $ua = Plagger::UserAgent->new;
    my $res = $ua->get($asx_url);
    my $content = $res->content;
    $content =~ m!<REF HREF="([^"]+${key}_mh.wmv)"!;
    return $1;
}
