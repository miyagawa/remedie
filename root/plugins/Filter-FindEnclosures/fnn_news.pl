# XXX This doesn't work
# author: Tatsuhiko Miyagawa

sub handle {
    my ($self, $url) = @_;
    $url =~ qr!http://www.fnn-news.com/news/headlines/articles!;
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    $args->{content} =~ m!(/news/video/FNN_viewer)\?(.*?jpg_name=(.*?\.jpg))!
        or return;

    my($swf, $query, $thumb) = ($1, $2, $3);

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://www.fnn-news.com${swf}.swf?${query}");
    $enclosure->type("application/x-shockwave-flash");
    $enclosure->thumbnail({ url => "http://www.fnn-news.com${thumb}" });
    return $enclosure;
}
