sub init {
    my $self = shift;
    $self->{handle} = '^/\w+$';
}

sub find {
    my ($self, $args) = @_;

    my($id) = URI->new($args->{url})->path
        or return;
    $id =~ s!^/!!;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://www.twitvid.com/player/$id");
    $enclosure->type('application/x-shockwave-flash');
    $enclosure->width(425);
    $enclosure->height(344);
    return $enclosure;
}

sub upgrade {
    my($self, $args) = @_;

    my $enclosure = $args->{enclosure};
    my $id = ($enclosure->url =~ m!/player/(\w+)$!)[0] or return;
    unless ($enclosure->thumbnail) {
        $enclosure->thumbnail({
            url => "http://cdn.twitvid.com/thumbnails/$id.jpg",
            width => 320, height => 24,
        });
    }
}

# autostart=1 works if http://kevin.twitvid.com/mediaplayer/player.swf is used

