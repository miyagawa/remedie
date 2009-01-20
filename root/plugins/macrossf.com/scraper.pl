# http://www.macrossf.com/radio/radio.html
sub init {
    my $self = shift;
    $self->{handle} = "/radio/radio.html";
}

sub build_scraper {
    scraper {
        process 'title', title => 'TEXT';
        process 'dt.clear + dd', description => 'TEXT';
        process 'dl.clear > dd.onair + dd', 'entries[]' => scraper {
            process 'a',
                    link      =>  '@href',
                    enclosure =>  '@href';
            process 'a>img',
                    thumbnail => '@src';
        };
        my $i = 0;
        process 'dl.clear > dd.onair', sub {
            result->{entries}->[$i++]->{title} = $_->as_text;
        };
        result->{thumbnail} = URI->new('http://macrossf.com/image/radio/logo_radio.jpg');
        result;
    };
}
