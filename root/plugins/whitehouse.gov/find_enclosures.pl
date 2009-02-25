# http://www.whitehouse.gov/feed/video/
use Web::Scraper;
sub init {
    my $self = shift;
    $self->{handle} = '/video/';
}

sub needs_content { 1 }

sub find {
    my($self, $args) = @_;

    my $res = scraper {
        process 'input[name="EMBED_URL"]', code => '@value';
    }->scrape($args->{content});

    my $url = ($res->{code} =~ /name="movie" value="(.*?)"/)[0] or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($url);
    $enclosure->type('application/x-shockwave-flash');
    return $enclosure;
}
