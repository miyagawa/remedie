sub init {
    my $self = shift;
    $self->{handle} = '/stream/\w+/\d+\w+\.htm';
}

sub find {
    my($self, $args) = @_;

    my $uri = $args->{url};
    $uri =~ s/\.htm$/\.asx/ or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($uri);
    $enclosure->type('video/x-ms-asf');

    return $enclosure;
}

