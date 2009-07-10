use Web::Scraper::LibXML;
sub init {
    my $self = shift;
    $self->{handle} = '/watched/\d+';
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    my $res = scraper {
        process ".service>a", link => '@href';
    }->scrape($args->{content});

    my $link = $res->{link} or return;

    $self->parent->add_enclosure($args->{entry}, [ 'a', { href => $link } ], 'href');
}
