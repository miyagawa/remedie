# http://movie.goo.ne.jp/schedule/thisweek.html
use Web::Scraper;
sub init {
    my $self = shift;
    $self->{handle} = ".";
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    my $id = ($args->{entry}->link =~ m!(MOVCSTD\d+)!)[0]
        or return;

    my $res = scraper {
        process '//a[contains(@href, "27.asx")]', movie => '@href';
        process '//p[@class="imagel"]//img[contains(@src, "_01.jpg")]', thumbnail => '@src';
    }->scrape($args->{content});

    return unless $res->{movie};

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://movie.goo.ne.jp/contents/movies/$id/".$res->{movie});
    $enclosure->type('video/x-ms-asf');
    $enclosure->thumbnail({ url => $res->{thumbnail}}) if $res->{thumbnail};
    return $enclosure;
}
