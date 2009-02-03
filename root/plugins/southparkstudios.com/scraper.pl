sub init {
    my $self = shift;
    $self->{handle} = '/guide/season/';
}

sub build_scraper {
    scraper {
        process "li.grid_item", 'entries[]' => scraper {
            my $ep;
            process ".epnumber", _ep => sub { $ep = $_->as_text };
            process ".eptitle", title => [ 'TEXT', sub { "$ep $_" } ];
            process ".epdate", date => 'TEXT';
            process ".epdesc", body => 'TEXT';
            process "a.overlay", link => '@href';
            process "a.watch_full_episode",
                enclosure => [ '@href',
                               sub { +{ url => $_, type => 'text/html' } } ],
            process ".image img", thumbnail => '@src';
        };
        process 'title', title => 'TEXT';
    };
}
