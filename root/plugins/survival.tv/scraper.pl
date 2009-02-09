# http://survival.tv/thebriefingroom/
# http://survival.tv/downloads
sub build_scraper {
    scraper {
        process "title", title => 'TEXT';
        process ".podcast li", "entries[]" => scraper {
            process '//a[./img[contains(@alt, "Quicktime")]]',
                link => '@href', enclosure => [ '@href', sub { +{ url => $_, type => 'video/quicktime' } } ];
            process 'span', title => 'TEXT';
        };
    };
}
