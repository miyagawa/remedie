sub init {
    my $self = shift;
    $self->{handle} = '/feeds/base/videos';
}

sub discover {
    my($self, $uri) = @_;

    unless ($uri->query_param('orderby')) {
        $uri->query_param(orderby => 'published');
    }

    return $uri;
}
