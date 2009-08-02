sub init { }

sub build_scraper {
    scraper {
        process ".ipw_contents", "entries[]" => scraper {
            process '//div[contains(@class, "title_")]', title => 'TEXT';
            process ".subtitle", body => 'TEXT';
            process "img.top_mainimg", thumbnail => '@src';
            process ".button_play_flash a", link => '@href';
        };
        process "title", title => 'TEXT';
    };
};
