# http://www.so-net.ne.jp/minnanotv/rakugo/rakugokai.html
sub init {
    my $self = shift;
    $self->{handle} = "/minnanotv/rakugo/";
}

sub build_scraper {
    scraper {
        process  '//tr[td[./table[.//tr[td[a[contains(@href, ".wvx")]]] and .//span]]]', 'entries[]' => scraper {
            process 'span.title', title => 'TEXT';
            process 'span.honbun', body => 'TEXT';
            process '//a[contains(@href,".wvx")]', enclosure => [ '@href',
            sub { +{ url => $_, type => 'video/x-ms-wvx' } } ];
            process '//img[contains(@src, ".jpg")]', thumbnail => '@src';
            process '//a[@target="_blank"]', link => '@href';
        };
        process 'title', title => 'TEXT';
    };
}
