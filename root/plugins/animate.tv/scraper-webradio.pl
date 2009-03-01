# http://www.animate.tv/digital/web_radio/detail_104.html
sub init {
    my $self = shift;
    $self->{handle} = "/digital/web_radio/";
}

sub build_scraper {
    scraper {
        process '//table[@width="565" and descendant::a[contains(@href,".asx")] ]', 'entries[]' => scraper {
            process 'td.main_title2', title => 'TEXT';
            process '//table[@width="553"]//td[@class="main_txt1"]', body => 'TEXT';
            process 'td.main_txt2', date => ['TEXT',
                    sub { s/.*?(\d{4})\x{5e74}(\d{1,2})\x{6708}(\d{1,2})\x{65e5}.*/$1-$2-$3/ } ];
            process '//a[contains(@href, ".asx")]', enclosure => [ '@href',
                    sub { +{ url => $_, type => 'video/x-ms-asf' } } ];
            process '//a[contains(@href, ".asx")]', link => '@href';
        };
        process 'title', title => 'TEXT';
        process '//*[@class="main_title3"]//img[contains(@src, "logo")]',
                image => '@src';
        process '//table[@width="573"]//td[@class="main_txt1"]',
                description => 'TEXT';
    };
}
