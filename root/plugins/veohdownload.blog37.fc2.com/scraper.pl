# upgrades http://veohdownload.blog37.fc2.com/blog-category-52.html
# skip RSS Discovery
use URI::QueryParam;

sub build_scraper {
    scraper {
        process "title", title => 'TEXT';
        process ".entry_block", "entries[]" => scraper {
            process ".entry_title a", title => 'TEXT';
            process '//a[contains(@href, "veoh.com")]', link => '@href';
            process '//a[contains(@href, "veoh.com")]/img', thumbnail => '@src';
            process "embed", link => [ '@src', sub { return "http://www.veoh.com/videos/" . $_->query_param('permalinkId') } ];
        };
    };
}

