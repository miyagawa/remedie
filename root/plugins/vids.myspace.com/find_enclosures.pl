sub init {
    my $self = shift;
    $self->{handle} = '/index.cfm\?.*videoid=';
}

sub find {
    my ($self, $args) = @_;

    my($id) = $args->{url} =~ m/videoid=(\d+)/i;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://mediaservices.myspace.com/services/media/embed.aspx/m=$id,t=1,mt=video,ap=1,searchID=,primarycolor=,secondarycolor=");
    $enclosure->width(640);
    $enclosure->height(400);
    $enclosure->type('application/x-shockwave-flash');
    return $enclosure;
}
