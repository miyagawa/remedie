# http://www.mxtv.co.jp/mxnews/mx_free/tokyo/
sub init {
    my $self = shift;
    $self->{handle} = "/mxnews/mx_free/tokyo/";
}

sub build_scraper {
    scraper {
        process  '//table[@class="movie_table"]', 'entries[]' => scraper {
            process '//td[@class="movie_title"]//a', title => 'TEXT';
            process '//td[@class="movie_date"]', date => 'TEXT';
            process '//td[@class="movie_title"]//a[contains(@href,".asx")]', enclosure => [ '@href',
            sub { +{ url => $_, type => 'video/x-ms-asf' } } ];
            process '//td[@class="movie_pic"]//img', thumbnail => '@src';
        };
        result->{title} = 'TOKYO MX ＊ TOKYO MX NEWS 「TOKYO Watcher」';
        result;
    };
}
