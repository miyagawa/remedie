# http://www.pbs.org/now/
sub init {
    my $self = shift;
    $self->{handle} = '/shows/\d+';
}

sub find {
    my ($self, $args) = @_;

    my ($id) = $args->{entry}->link =~ m!/shows/(\d+)/index.html!
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://www-tc.pbs.org/now/video/PBS-NOW1${id}V_480.flv");
    $enclosure->type("application/x-shockwave-flash");
    $enclosure->thumbnail({ url => "http://www-tc.pbs.org/now/shows/${id}/images/video.jpg" });
    return $enclosure;
}
