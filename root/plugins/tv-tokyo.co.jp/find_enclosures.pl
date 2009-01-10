# author: Tatsuhiko Miyagawa
sub init {
    my $self = shift;
    $self->{handle} = '/(nms|emorning|newsfine|wbs)/\d+';
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    my($flv, $thumb, $base) = $args->{content} =~ m!file=(\w+?\.flv)&image=(.*?\.jpg).*?streamer=(.*?)\'!
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($base . $flv);
    $enclosure->type("video/x-flv");
    $enclosure->thumbnail({ url => $thumb });
    return $enclosure;
}
