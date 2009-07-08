sub init {
    my $self = shift;
    $self->{handle} = '/webtv/recipie/recipie\d+\.html';
}

sub needs_content { 1 }

sub find {
    my($self, $args) = @_;

    my($comment)  = $args->{content} =~ m|<!--(.*?)//-->|s;
    my %js_params = $comment =~ m@\s*(bv_\w+)\s*=\s*"(.*?)"@g
        or return;

    my $uri = URI->new("http://video.bemoove.jp/plugin/showVideoSelect.php");
    $uri->query_form(charset => "UTF-8", %js_params, bv_host => 'ikkostyle.jp', bv_controlbar => 'bottom');

    my $content = $self->parent->fetch_content($uri);
    my $flashvars = ($content =~ /var flashvars = "(.*?)"/)[0];
    my %param = $flashvars =~ /&(\w+)=([^&]+)/g;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($param{file});
    $enclosure->thumbnail({ url => $param{image} });
    $enclosure->width($param{width});
    $enclosure->height($param{height});

    return $enclosure;
}


