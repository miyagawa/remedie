sub init { }

sub build_scraper {
    scraper {
        process ".backnoItem", "entries[]" => scraper {
            process ".title_stapa", title => 'TEXT';
            process ".subtitle", body => 'TEXT';
            process "img.top_mainimg", thumbnail => '@src';
            process ".button_play_flash a", link => '@href';
        };
        process "title", title => 'TEXT';
    };
};
