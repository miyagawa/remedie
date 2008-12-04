# author: Tatsuhiko Miyagawa
sub init {
    my $self = shift;
    $self->{domain} = "mtvmusic.com";
    $self->{handle} = 'videos/\d+';
}

sub needs_content { 0 }

sub find {
    my ($self, $args) = @_;

    my($id) = $args->{url} =~ qr!videos/(\d+)!
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://media.mtvnservices.com/mgid:uma:video:mtvmusic.com:$id");
    $enclosure->type('application/x-shockwave-flash');
    return $enclosure;
}
