# http://www.mxtv.co.jp/mxnews/ny1news/
sub init {
    my $self = shift;
    $self->{handle} = "/mxnews/ny1news/";
}

sub build_scraper {
    scraper {
        process  '//tr[td[@class="ny1_day"]]', 'entries[]' => scraper {
            process '//td[@class="ny1_subtitle" and ./a]', title => 'TEXT';
            process '//td[@class="ny1_day" and ./a]', date => 'TEXT';
            process '//td[@class="ny1_day"]//a[contains(@href,".html")]', enclosure => [ '@href',
            sub { m!/mxnews/news_ny1/(\d+)\.html! and return +{ url => "http://www.mxtv.co.jp/meta2/ny1news/$1_high.asx", type => 'video/x-ms-asf' } } ];
            process '//td[@class="ny1_day"]//a[contains(@href,".html")]', thumbnail => [ '@href',
            sub { m!/mxnews/news_ny1/(\d+)\.html! and return +{ url => "http://www.mxtv.co.jp/mxnews/img/ny1_img/$1.jpg" } } ];
            process '//td[@class="ny1_day"]//a[contains(@href,".html")]', link => '@href';
        };
        process 'title', title => 'TEXT';
        result->{description} = 'TOKYO MXの姉妹局「NY1」のニュースを月曜から金曜まで毎日お伝えします。';
        result;
    };
}
