sub init {
    my $self = shift;
    $self->{handle} = '/courses/';
}

sub build_scraper {
    scraper {
        process "ol.long-description li", 'entries[]' => scraper {
            process ".description a", link => '@href', title => 'TEXT';
            process '//img[contains(@src, "lectures/")]', thumbnail => '@src';
        };
        process "title", title => 'TEXT';
    };
}
