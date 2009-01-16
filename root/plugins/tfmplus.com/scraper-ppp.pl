# http://www.tfmplus.com/ppp/
sub init {
    my $self = shift;
    $self->{handle} = "/ppp/";
}

sub build_scraper {
    scraper {
        process  '//table[@width="850" and descendant::a[contains(@href,".asx")] ]', 'entries[]' => scraper {
            process 'td.day', title => 'TEXT', date => 'TEXT';
            process 'td.font11p', body => 'TEXT';
            process '//a[contains(@href, ".asx")]', enclosure => [ '@href',
            sub { +{ url => $_, type => 'video/x-ms-asf' } } ];
            process 'id("index7_r1_c1")', thumbnail => '@src';
            process '//a[contains(@href, ".asx")]', link => '@href';
        };
        process 'title', title => 'TEXT';
    };
}
