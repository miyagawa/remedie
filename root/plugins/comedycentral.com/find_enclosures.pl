# author: Tatsuhiko Miyagawa
sub init {
    my $self = shift;
    $self->{handle} = 'videos/index\.jhtml\?videoId=';
}

sub find {
    my ($self, $args) = @_;

    my($id) = URI->new($args->{url})->query_param('videoId')
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://media.mtvnservices.com/mgid:cms:item:comedycentral.com:$id");
    $enclosure->width(360);
    $enclosure->height(310);
    $enclosure->type('application/x-shockwave-flash');
    return $enclosure;
}
