# author: Tatsuhiko Miyagawa
# XXX this doesn't work because their DivX server blocks GETs without Referer
use Web::Scraper;

sub init {
    my $self = shift;
    $self->{handle} = "watch";
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    my $res = scraper {
        process "param[name='src']", src => '@value';
        process "param[name='previewImage']", thumb => '@value';
    }->scrape($args->{content});

    return unless $res->{src};

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($res->{src});
    $enclosure->type('video/divx');
    $enclosure->width(710);
    $enclosure->height(405);
    $enclosure->thumbnail({ url => $res->{thumb} });

    return $enclosure;
}
