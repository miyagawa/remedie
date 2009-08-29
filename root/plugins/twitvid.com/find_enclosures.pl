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

# autostart=1 works if http://kevin.twitvid.com/mediaplayer/player.swf is used

