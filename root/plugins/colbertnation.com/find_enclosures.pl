# author: Tatsuhiko Miyagawa
sub init {
    my $self = shift;
    $self->{handle} = 'videos/\d+';
}

sub find {
    my ($self, $args) = @_;

    my($id) = $args->{url} =~ qr!videos/(\d+)!
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://media.mtvnservices.com/mgid:cms:item:comedycentral.com:$id");
    $enclosure->width(360);
    $enclosure->height(310);
    $enclosure->type('application/x-shockwave-flash');
    return $enclosure;
}
