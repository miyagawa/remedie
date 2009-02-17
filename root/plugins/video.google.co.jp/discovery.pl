sub init {
    my $self = shift;
    $self->{handle} = '/videosearch\?';
}

sub discover {
    my($self, $uri) = @_;

    $uri->query_param(oe => 'utf-8');

    # Sort results by date
    $uri->query_param(so => '1') unless $uri->query_param('so');

    return $uri;
}
