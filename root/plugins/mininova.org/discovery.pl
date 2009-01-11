sub init {
    my $self = shift;
    $self->{handle} = '/search/';
}

sub discover {
    my($self, $uri) = @_;

    if (my $qs = $uri->query_param('search')) {
        return "http://www.mininova.org/rss/$qs";
    } elsif ($uri->path =~ m!/search/([^=\?]+)!) {
        return "http://www.mininova.org/rss/$1";
    } else {
        return;
    }
}

