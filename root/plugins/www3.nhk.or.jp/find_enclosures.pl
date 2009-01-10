# author: Tatsuhiko Miyagawa
sub init {
    my $self = shift;
    $self->{handle} = '/news/[kt]\d+.html';
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    # flv uses rtmp. JW FLV player supports RTMP but needs a hack on the JS side
    my($asx_url, $key) = $args->{content} =~ m!wmvHigh = "(.*/cgibin/((.*?)_(.*?)_(.*?))(?:_(.*?))?_mh.cgi)"!
        or return;
    my $url = $self->find_mms_url($asx_url, $key) or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($url);
    $enclosure->type("video/x-ms-wmv");

    if ($args->{content} =~ m!switchPlayer.*?src="(K[\d_]+\.jpg)" width="(\d+)" height="(\d+)"!) {
        $enclosure->thumbnail({ url => "http://www3.nhk.or.jp/news/$1", width => $2, height => $3 });
    }

    return $enclosure;
}

sub find_mms_url {
    my ($self, $asx_url, $key) = @_;

    my $content = Plagger->context->current_plugin->fetch_content($asx_url) or return;
    $content =~ m!<REF HREF="([^"]+${key}_mh.wmv)"! or return;
    return $1;
}
