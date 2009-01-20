# http://www.macrossf.com/radio/radio.html
sub init {
    my $self = shift;
    $self->{handle} = "/radio/radio.html";
}

sub build_scraper {
    my $i = 0;
    scraper {
        process 'title', title => 'TEXT';
        process 'dt.clear + dd', description => 'TEXT';
        process 'dl.clear > dd.onair + dd', 'entries[]' => scraper {
            process 'a',
                    link      =>  '@href',
                    enclosure => [ '@href',
                        sub { +{ url => $_, type => 'video/x-ms-asf' } } ];
            process 'a>img',
                    thumbnail => '@src';
        };
        process 'dl.clear > dd.onair', sub {
            result->{entries}->[$i]->{title} = $_->as_text;
            $i++;
        };
        result->{thumbnail} = URI->new('http://macrossf.com/image/radio/logo_radio.jpg');
        result;
    };
}
