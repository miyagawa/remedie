use Web::Scraper::LibXML;
sub init {
    my $self = shift;
    $self->{handle} = '/news/\?num=\d+';
}

sub needs_content { 1 }

# Just a standard .asx link, but make sure to pick up the right link
sub find {
    my($self, $args) = @_;

    my $res = scraper {
        process '//a[contains(@href, "v300.asx")', link => '@href';
    }->scrape($args->{content});

    my $url = $res->{link} or return;
    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($url);

    return $enclosure;
}
