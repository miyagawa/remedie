sub init {
    my $self = shift;
    $self->{handle} = '/doc/\d+';
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    my ($url) = $args->{content} =~ m!(http://d\.scribd\.com/ScribdViewer\.swf\?document_id=.*?)&quot;!
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($url);
    $enclosure->type("application/x-shockwave-flash");

    return $enclosure;
}
