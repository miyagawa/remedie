sub init {
    my $self = shift;
    $self->{handle} = '/library/';
}

sub build_scraper {
    scraper {
        process "title", title => 'TEXT';
        process ".mediathumb-mug>a", 'entries[]' => scraper {
            process "a", title => '@title', link => '@href';
            process "div.mediathumb-mug-image", thumbnail => [ '@style',
                                                               sub { /url\('(.*?)'\)/ and return URI->new($1) } ];
        };
    };
}
