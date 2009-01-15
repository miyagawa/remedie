sub init {
    my $self = shift;
    $self->{handle} = ".";
}


sub find {
    my ($self, $args) = @_;
    my $uri = URI->new($args->{url});
    my $video_id = ($uri =~ m!/clip/\?content_id=([\w\-]+)!)[0] or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://player.cliplife.jp/player_external_03.swf?clipinfo=http%3A%2F%2Fstream.cliplife.jp%2Fclipinfo%2Fclipinfo_03.php%3Fcontent_id%3D$video_id");
    $enclosure->type('application/x-shockwave-flash');
    return $enclosure;
}
