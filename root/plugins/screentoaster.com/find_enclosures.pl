# author: Yasuhiro Matsumoto

sub init {
    my $self = shift;
    $self->{handle} = ".";
}


sub find {
    my ($self, $args) = @_;
    my $uri = URI->new($args->{url});
    my $video_id = ($uri =~ m!/watch/([\w\-]+)!)[0] or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://www.screentoaster.com/swf/STPlayer.swf?video=$video_id");
    $enclosure->type('application/x-shockwave-flash');
    return $enclosure;
}
