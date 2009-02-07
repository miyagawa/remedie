sub init {
    my $self = shift;
    $self->{handle} = "/watch\.do";
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    my($url) = $args->{content} =~ m!src="([^"]*mcj\.php\?id=[^"]*)!
        or return;

    $url =~ s/mcj\.php/mcs.swf/;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($url);
    $enclosure->width(320);
    $enclosure->height(240);
    $enclosure->type('application/x-shockwave-flash');
    return $enclosure;
}
