sub init {
    my $self = shift;
    $self->{handle} = '^/\d+\.html$';
}

sub needs_content { 1 }

sub find {
    my($self, $args) = @_;

    my $id = ($args->{content} =~ /movie=(\d+)\.cgi\.300k/)[0]
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("mms://wmt-od.stream.ne.jp/ntv/news/${id}_300k.wmv");
    $enclosure->thumbnail({ url => "http://www.news24.jp/pictures/${id}_160x120.jpg" });
    $enclosure->width(320);
    $enclosure->height(306);

    return $enclosure;
}
