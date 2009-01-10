# author: Tatsuhiko Miyagawa
sub init {
    my $self = shift;
    $self->{handle} = "/watch/";
}

sub needs_content { 0 }

sub find {
    my ($self, $args) = @_;
    my($id) = $args->{url} =~ qr!watch/(\w\w\d+)!
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://ext.nicovideo.jp/thumb_watch/$id");
    $enclosure->type('application/javascript');
    $enclosure->thumbnail({ url => $self->_thumbnail_for($id) });
    return $enclosure;
}

sub _thumbnail_for {
    my($self, $id) = @_;

    if (0) {
    my $res = Plagger::UserAgent->new->fetch("http://www.nicovideo.jp/api/getthumbinfo/$id");

    unless ($res->is_error) {
        my $doc = XML::LibXML->new->parse_string($res->content);

        my @nodes = $doc->findnodes('//thumbnail_url');
        if (@nodes) {
            return $nodes[0]->textContent;
        }
    }
    }

    $id =~ s!^\w\w!!;
    return "http://tn-skr1.smilevideo.jp/smile?i=$id";
}
