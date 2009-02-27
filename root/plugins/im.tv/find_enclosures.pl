sub init {
    my $self = shift;
    $self->{handle} = 'vlog/personal/\d+/\d+';
}

sub find {
    my ($self, $args) = @_;

    my ($mid, $id) = $args->{entry}->link =~ m!vlog/personal/(\d+)/(\d+)!i
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://myvlog.im.tv/index_key2.swf?id=$id&mid=$mid&album=0");
    $enclosure->width(450);
    $enclosure->height(338);
    $enclosure->type("application/x-shockwave-flash");

    return $enclosure;
}
