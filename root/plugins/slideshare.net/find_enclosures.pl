use URI;
sub init {
    my $self = shift;
    $self->{handle} = ".";
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    my ($url) = $args->{content} =~ m!<param name="movie" value="([^"]*)"!
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url(URI->new($url));
    $enclosure->type('application/x-shockwave-flash');
    return $enclosure;
}
