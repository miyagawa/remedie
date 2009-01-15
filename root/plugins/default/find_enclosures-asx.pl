# author: Tatsuhiko Miyagawa
use XML::LibXML;
sub init {
    my $self = shift;
    $self->{handle} = "\.asx"; # XXX this really needs to be the handle for upgrade, not find
}


sub find { }

sub upgrade {
    my($self, $args) = @_;

    my $enclosure = $args->{enclosure};
    return unless $enclosure->type eq 'video/x-ms-asf' && $enclosure->url =~ m!^http://!;

    my $content = Plagger->context->current_plugin->fetch_content($enclosure->url)
        or return;

    my $doc = XML::LibXML->new->parse_string($content);
    my @ref = $doc->findnodes('//ref') or return;

    my $url = $ref[0]->getAttribute('href') || $ref[0]->getAttribute('HREF')
        or return;
    $enclosure->url($url);
    $enclosure->type(Plagger::Util::mime_type_of($url) || "video/x-ms-asf");

    Plagger->context->log(info => "Enclosure upgraded to $url " . $enclosure->type);
}

