# author: Yasuhiro Matsumoto
use Web::Scraper;
sub init {
    my $self = shift;
    $self->{handle} = "/ann/news/";
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    my $res = scraper {
        process "//a[contains(\@href, '300k')]", movie => sub { my ($link) = $_->attr('onClick') =~ /(mms:[^']+)/; $link };
        process "//img[contains(\@src, 'pict/')]", thumbnail => '@src';
    }->scrape($args->{content}, $args->{url});

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($res->{movie});
    $enclosure->type("video/x-ms-wmv");
    $enclosure->thumbnail({ url => $res->{thumbnail} });
    return $enclosure;
}
