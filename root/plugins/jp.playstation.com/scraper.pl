sub init {
    my $self = shift;
    $self->{handle} = "/psworld/movie/";
}

sub build_scraper {
    scraper {
        process '//tr[td[@class="mplayarea" and ./a[contains(@href, ".asx")]]]', 'entries[]' => scraper {
            process 'td.txtarea > h3', title => 'TEXT';
            process 'p.moviedata', body => 'TEXT';
            process '//a[contains(@href,".asx")]', enclosure => [ '@href',
                                                                  sub { +{ url => $_, type => 'video/x-ms-asf' } } ];
            process 'img.pborder', thumbnail => '@src';
            process '//img[@class="official"]/..', link => '@href';
        };
        process 'title', title => 'TEXT';
    };
}
