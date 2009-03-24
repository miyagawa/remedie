sub init {
    my $self = shift;
    $self->{handle} = '/view/';
}

sub find {
    my($self, $args) = @_;

    my $id = (URI->new($args->{url})->path =~ m!^/view/([0-9a-f\-]+)!)[0]
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://dotsub.com/media/$id/e/m");
    $enclosure->thumbnail({ url => "http://dotsub.com/media/$id/p" });
    $enclosure->type("text/html");
    $enclosure->width(420);
    $enclosure->height(347);

    return $enclosure;
}
