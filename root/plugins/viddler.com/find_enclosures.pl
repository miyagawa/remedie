# author: Tatsuhiko Miyagawa
sub init {
    my $self = shift;
    $self->{handle} = '/explore/.*videos/\d+/$';
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    my($token) = $args->{content} =~ /currentMovieToken\s*=\s*'(\w+)'/
        or return;
    my($width, $height) = $args->{content} =~ /publisher\.swf",\s*"viddler",\s*"(\d+)",\s*"(\d+)"/;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://www.viddler.com/player/$token/");
    $enclosure->width($width);
    $enclosure->height($height);
    $enclosure->type('application/x-shockwave-flash');
    return $enclosure;
}

sub upgrade {
    my($self, $args) = @_;

    my $enclosure = $args->{enclosure};
    return unless $enclosure->type eq 'application/x-shockwave-flash';

    my($token) = $enclosure->url =~ m!/player/(\w+)!
        or return;

    $enclosure->thumbnail({
        url => "http://www.viddler.com/thumbnail.action?token=$token&size=1",
    });
}
