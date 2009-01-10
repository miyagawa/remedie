# author: Tatsuhiko Miyagawa
sub init {
    my $self = shift;
    $self->{handle} = "/netstar/.*mov_";
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    $args->{content} =~ m!<embed src="(.*?)\.swf"!i
        or return;

    my $id = $1;
    (my $thumb_id = $id) =~ s/sono(\d+)/s$1/;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://www.nhk-ep.co.jp/netstar/flv/${id}.flv");
    $enclosure->type("video/x-flv");
    $enclosure->thumbnail({ url => "http://www.nhk-ep.co.jp/netstar/img/mov_thumb_${thumb_id}.jpg" });
    return $enclosure;
}
