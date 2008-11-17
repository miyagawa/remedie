# author: Tatsuhiko Miyagawa

sub handle {
    my ($self, $url) = @_;
    $url =~ qr!http://www3.nhk.or.jp/news/t\d+.html!;
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    # flv uses rtmp. JW FLV player supports RTMP but needs a hack on the JS side
    $args->{content} =~ m!wmvHigh = "(.*?)"!
        or return;
    my $url = $1;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($url);
    $enclosure->type("video/wmv");

    if ($args->{content} =~ m!switchPlayer.*?src="(K[\d_]+\.jpg)" width="(\d+)" height="(\d+)"!) {
        $enclosure->thumbnail({ url => "http://www3.nhk.or.jp/news/$1", width => $2, height => $3 });
    }

    return $enclosure;
}
