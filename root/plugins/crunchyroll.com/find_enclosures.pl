sub init {
    my $self = shift;
    $self->{handle} = '/media-\d+/';
}

sub find {
    my($self, $args) = @_;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($args->{url});
    $enclosure->type('text/html');
    return $enclosure;
}
