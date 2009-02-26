sub init {
    my $self = shift;
    $self->{handle} = '/video/\w+';
}

sub find {
    my ($self, $args) = @_;

    (my $url = $args->{entry}->link) =~ s!/video/!/player/!
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($url);
    $enclosure->width(640);
    $enclosure->height(480);
    $enclosure->type("application/x-shockwave-flash");

    return $enclosure;
}
