# http://www.animate.tv/digital/web_radio/detail_104.html
sub init {
    my $self = shift;
    $self->{handle} = "/digital/web_radio/detail_104.html";
}

sub build_scraper {
    scraper {
        process '//table[@width="565" and descendant::a[contains(@href,".asx")] ]', 'entries[]' => scraper {
            process 'td.main_title2 > p', title => 'TEXT';
            process '//table[@width="553"]//td[@class="main_txt1"]', body => 'TEXT';
            process 'td.main_txt2', date => 'TEXT';
            process '//a[contains(@href, ".asx")]', enclosure => [ '@href',
            sub { +{ url => $_, type => 'video/x-ms-asf' } } ];
            process '//a[contains(@href, ".asx")]', link => '@href';
        };
        process 'title', title => 'TEXT';
        process 'span.main_title3 > strong > img', image => ['@src', sub { +{ url => $_} } ];
        process '//td[@class="main_txt1" and descendant::a[contains(@href,"zetsubou_mail.html")] ]', 'description' => 'TEXT';
    };
}
