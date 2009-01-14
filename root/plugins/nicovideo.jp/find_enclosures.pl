# author: Tatsuhiko Miyagawa
use HTML::TreeBuilder::XPath;

sub init {
    my $self = shift;
    $self->{handle} = "/watch/";
}

sub needs_content { 0 }

sub find {
    my ($self, $args) = @_;
    my($id) = $args->{url} =~ qr!watch/(\w\w[^/?]+|\d+)!
        or return;

    my $thumbnail = $self->_thumbnail_for($args->{entry});

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://ext.nicovideo.jp/thumb_watch/$id");
    $enclosure->type('application/javascript');
    $enclosure->thumbnail({ url => $thumbnail }) if $thumbnail;
    return $enclosure;
}

sub _thumbnail_for {
    my($self, $entry) = @_;
    my $tree = HTML::TreeBuilder::XPath->new_from_content($entry->body);
    return $tree->findvalue('//p[@class="nico-thumbnail"]/img/@src');
}
