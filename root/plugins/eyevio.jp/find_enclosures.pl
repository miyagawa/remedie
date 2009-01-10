# author: Tatsuhiko Miyagawa
# TODO replace the original video/3gpp
sub init {
    my $self = shift;
    $self->{handle} = "/movie/";
}

sub find {
    my ($self, $args) = @_;
    my $uri = URI->new($args->{url});
    my($video_id) = $uri->path =~ m!/movie/(\d+)!
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://eyevio.jp/fla/emp_embed_solo.swf?movieId=$video_id");
    $enclosure->type('application/x-shockwave-flash');
    return $enclosure;
}
