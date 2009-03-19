sub init {
    my $self = shift;
    $self->{handle} = '/clip/[0-9a-f]+';
}

sub needs_content { 1 }

sub find {
    my($self, $args) = @_;

    my %param = $args->{content} =~ /swf\.addVariable\('(\w+)', '(.*?)'\)/g;

    my $uri = URI->new("http://www.justin.tv/widgets/jtv_tip_embed.swf");
    $uri->query_form(
        auto_play => 'true', # xxx doesn't seem to work?
        channel => $param{channel},
        tip_id => $param{tip_id},
    );

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($uri);
    $enclosure->type("application/x-shockwave-flash");
    $enclosure->width(320);
    $enclosure->height(263);
    $enclosure->thumbnail({ url => "http://static-cdn.justin.tv/jtv.thumbs/$param{tip_id}-125x94.jpg" });

    return $enclosure;
}
