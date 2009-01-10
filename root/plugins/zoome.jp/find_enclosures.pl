# author: Tatsuhiko Miyagawa
use Web::Scraper;
sub init {
    my $self = shift;
    $self->{handle} = "diary";
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    my $res = scraper {
        process 'input[id="mypage_diary_xml"]', xml => '@value';
        process 'input[id="mypage_movie_width"]', width => '@value';
        process 'input[id="mypage_movie_height"]', height => '@value';
    }->scrape(\$args->{content});

    if ($res->{xml}) {
        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url("http://www.zoome.jp/swf/zpmmdiap.swf?baseXML=$res->{xml}");
        $enclosure->width($res->{width});
        $enclosure->height($res->{height});
        $enclosure->type('application/x-shockwave-flash');
        return $enclosure;
    }

    return;
}
