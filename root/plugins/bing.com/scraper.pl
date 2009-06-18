use URI::QueryParam;
sub init {
    my $self = shift;
    $self->{handle} = '/videos/';
}

sub build_scraper {
    scraper {
        process "title", title => 'TEXT';
        process 'div.sc_vc0', "entries[]" => scraper {
            process "img", thumbnail => '@src', title => '@alt',
                link => [ '@src', sub { return $_->query_param('url') } ];
        };
    };
}

