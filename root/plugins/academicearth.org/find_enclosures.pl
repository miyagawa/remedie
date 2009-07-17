use Web::Scraper::LibXML;
sub init {
    my $self = shift;
    $self->{handle} = '/lectures/';
}

sub needs_content { 1 }

sub find {
    my($self, $args) = @_;

    my $res = scraper {
        process "#video-embed textarea", code => 'TEXT';
    }->scrape($args->{content});

    if ($res->{code}) {
        $self->parent->find_enclosures(\$res->{code}, $args->{entry});
    }

    return;
}
