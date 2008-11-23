# author: Tatsuhiko Miyagawa
sub init {
    my $self = shift;
    $self->{domain} = "www.nhk-ep.co.jp";
    $self->{handle} = "/netstar/.*mov_";
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    $args->{content} =~ m!<embed src="(.*?)\.swf"!i
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://www.nhk-ep.co.jp/netstar/flv/$1.flv");
    $enclosure->type("video/x-flv");
    $enclosure->thumbnail({ url => "http://www.nhk-ep.co.jp/netstar/img/mov_thumb_$1.jpg" });
    return $enclosure;
}
