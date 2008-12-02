# author: Yasuhiro Matsumoto
use URI;
use Web::Scraper;
sub init {
    my $self = shift;
    $self->{domain} = "www.tv-asahi.co.jp";
    $self->{handle} = "/ann/news/";
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    my $res = scraper {
        process "//a[contains(\@href, '300k')]", movie => sub { my ($link) = $_->attr('onClick') =~ /(mms:[^']+)/; $link };
        process "//img[contains(\@src, 'pict/')]", thumbnail => '@src';
    }->scrape($args->{content});

    my $id = $1;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($res->{movie});
    $enclosure->type("video/x-ms-wmv");
    $enclosure->thumbnail({ url => URI->new_abs($res->{thumbnail}, $args->{url}) });
    return $enclosure;
}
