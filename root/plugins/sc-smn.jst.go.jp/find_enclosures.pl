# http://sc-smn.jst.go.jp/index.asp
# author: otsune
use Web::Scraper;
sub init {
    my $self = shift;
    $self->{handle} = "/bangumi.asp";
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    my $res = scraper {
        process "//a[contains(\@href, '.asx')]", asx_url => '@href';
        process "//img[\@width='133' and \@height='100']", thumbnail => '@src';
    }->scrape($args->{content}, $args->{url});

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($res->{asx_url});
    $enclosure->type("video/x-ms-asf");
    $enclosure->thumbnail({ url => $res->{thumbnail} });
    return $enclosure;
}
