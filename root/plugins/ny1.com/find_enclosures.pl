# http://www.ny1.com/

sub init {
    my $self = shift;
    $self->{handle} = "/content/.*Default\.aspx";
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    my ($id) = $args->{content} =~ m!vids%3d(.*?)%.*player_large!
        or return;

    my ($thumbnail) = $args->{content} =~ m!imageUrl = '(.*?)'!;

    # asx file b0rked
    my $url = $self->find_flv_url("http://www.ny1.com/Video/BuildASX.ashx?vids=$id&StationId=1") or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($url);
    $enclosure->type("application/x-shockwave-flash");
    $enclosure->thumbnail({ url => $thumbnail }) if $thumbnail;
    return $enclosure;
}

sub find_flv_url {
    my ($self, $asx_url) = @_;

    my $content = Plagger->context->current_plugin->fetch_content($asx_url) or return;
    $content =~ m!<REF HREF="([^"]+\.flv)"! or return;
    return $1;
}
