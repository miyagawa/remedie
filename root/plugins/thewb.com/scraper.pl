# Check 'Skip RSS discovery'
sub init {
    my $self = shift;
    $self->{handle} = '/shows/';
}

sub build_scraper {
    scraper {
        process "title", title => [ 'TEXT', sub { (/Full episodes of (.*?),/)[0] || $_ } ];
        process "#tab1 div.showlistall", 'entries[]' => scraper {
            # use the pop_out link since it autostarts
            my $epinfo;
            process ".episodeinfo", sub { $epinfo = $_->as_text };
            process ".episodetitle > .ep_link", title => [ 'TEXT', sub { "$_ $epinfo" } ],
                link => [ '@id', sub { URI->new("http://www.thewb.com/shows/pop_out/$_/0") } ];
            process ".episodedesc", body => 'TEXT';
            process "img", thumbnail => '@src';
        };
    };
}
