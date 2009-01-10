# author: Tatsuhiko Miyagawa
sub init {
    my $self = shift;
    $self->{handle} = 'video/\w+/\w{3}\d+\.html';
}

sub needs_content { 1 }

sub find {
    my($self, $args) = @_;

    my($id, $key) = $args->{content} =~ /PeeVeePlayer\("(\d+)\/(.*?)\.flv"/
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->type("video/mp4");
    $enclosure->url("http://seel.peevee.tv/userdir/h.264hd/${id}/${key}.m4v");
    $enclosure->thumbnail({ url => "http://seel.peevee.tv/img/imagecache/${key}_1.jpg" });

    return $enclosure;
}

