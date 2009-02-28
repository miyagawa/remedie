sub init { }

sub build_scraper {
    scraper {
        process "title", title => 'TEXT';
        process '//a[contains(@class, "thumbLink") and ./img[contains(@src, ".veoh.com")]]', "entries[]" => scraper {
            process "a", title => '@title', link => '@href';
            process "img.lazyLoad", thumbnail => sub { URI->new($_->attr(' _src')) };
        };
    };
}

