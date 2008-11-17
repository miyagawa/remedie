# author: yusukebe

sub handle {
    my ($self, $url) = @_;
    $url =~ qr!http://www.veoh.com/videos/.*!;
}

sub find {
    my ($self, $args) = @_;
    my $id = $args->{url} =~ qr!videos/(.*)! ? $1 : "";
    $id = $1 if $id  =~ /(.*)\?/;
    return unless $id;
    my $ua = Plagger::UserAgent->new;
    my $url = "http://www.veoh.com/rest/video/$id/details";
    my $res = $ua->fetch($url);
    return if $res->is_error;
    my $content = $res->content;
    $content =~ /fullPreviewHashPath="(.*?)"/;
    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($1);
    $enclosure->type('video/flv');
    $enclosure->filename("$id.flv");
    return $enclosure;
}
