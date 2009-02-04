sub init {
    my $self = shift;
    $self->{handle} = '(?:/search.html\?.*search=|/search/videos/q/.*)';
}

sub discover {
    my($self, $uri) = @_;

    my $query = $uri->query_param('search') || ($uri->path =~ m!/search/videos/q/([^/]+)!)[0]
        or return;
    return URI->new("http://www.veoh.com/search/videos/q/$query/sort/most recent/lang/ALL")->canonical;
}
