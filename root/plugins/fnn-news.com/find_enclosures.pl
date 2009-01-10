# author: Tatsuhiko Miyagawa
sub init {
    my $self = shift;
    $self->{handle} = "/news/headlines/articles";
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    $args->{content} =~ m!/news/video/flv/(.*?_hd)\.txt&jpg_name=(.*?\.jpg)!
        or return;

    my($id, $thumb) = ($1, $2);

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://www.fnn-news.com/news/video/wmv/${id}_300.asx");
    $enclosure->type("video/x-ms-asf");
    $enclosure->thumbnail({ url => "http://www.fnn-news.com${thumb}" });
    return $enclosure;
}
