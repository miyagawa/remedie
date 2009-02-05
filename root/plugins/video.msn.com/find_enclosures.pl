# author: Tatsuhiko Miyagawa
sub init {
    my $self = shift;
    $self->{handle} = "/video\.aspx.*vid=";
}

# Just use iframe
sub find {
    my ($self, $args) = @_;

    # thumbnail is set by another enclosure
    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($args->{url});
    $enclosure->type('text/html');
    return $enclosure;
}

