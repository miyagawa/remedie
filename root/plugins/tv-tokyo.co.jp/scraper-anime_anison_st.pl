sub init {
    my $self = shift;
    $self->{handle} = '/anime/anison/st.html';
}

sub build_scraper {
    my $i = 0;
    scraper {
        process 'title', title => 'TEXT';
        process 'div.stbox', 'entries[]' => scraper {
            process '//img[@width="200"]', thumbnail => '@src';
            process '//img[@src="img/stbt_1m.jpg"]/..', enclosure => [ '@href', sub { +{ url => $_, type => 'video/x-ms-asf' } } ];
            process '//img[@src="img/stbt_1m.jpg"]/..', link => '@href';
            process '//div[@align="left"]', body => 'TEXT';
        };
        process 'div.sttitle', sub {
            use utf8;
            result->{entries}->[$i]->{title} = $_->as_text;
           (result->{entries}->[$i]->{date}  = $_->as_text) =~ s/.*?(\d{4})年(\d{1,2})月(\d{1,2})日.*/$1-$2-$3/;
            $i++;
        };
        result->{thumbnail} = URI->new('http://www.tv-tokyo.co.jp/anime/anison/img/logo.png');
        result;
    };
}
