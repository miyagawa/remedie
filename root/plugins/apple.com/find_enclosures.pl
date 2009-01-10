# author: Tatsuhiko Miyagawa
# http://images.apple.com/trailers/rss/newtrailers.rss
use Web::Scraper;
sub init {
    my $self = shift;
    $self->{handle} = "/trailers/";
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    my $res = scraper {
        process "//a[contains(\@href, '720p.mov')]", movie => '@href';
    }->scrape($args->{content});

    return unless $res->{movie};

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($res->{movie});
    $enclosure->type("video/quicktime");
    return $enclosure;
}
