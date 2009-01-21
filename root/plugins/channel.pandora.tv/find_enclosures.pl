# author: Tatsuhiko Miyagawa
use Remedie::JSON;

sub init {
    my $self = shift;
    $self->{handle} = "channel/video.ptv";
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    my($json) = $args->{content} =~ /"flvInfo":({.*?})}/
        or return;

    my $data = Remedie::JSON->decode($json);
    $data->{flv} =~ s/flvg\./flvorgx./;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($data->{flv});
    $enclosure->type('video/x-flv');
    $enclosure->length($data->{filesize});
    $enclosure->thumbnail({ url => $self->thumbnail_for($args->{url}) });
    if ($data->{isHD}) {
        $enclosure->width(1280);
        $enclosure->height(720);
    }

    return $enclosure;
}

sub thumbnail_for {
    my($self, $url) = @_;

    # URL http://channel.pandora.tv/channel/video.ptv?ch_userid=dkxtr291&skey=Perfume&prgid=33740367&categid=all&page=1
    # thumb http://imguser.pandora.tv/pandora/_channel_img_sm/d/k/dkxtr291/67/vod_thumb_33740367.jpg

    my $uri = URI->new($url);
    my $user  = $uri->query_param('ch_userid');
    my $prgid = $uri->query_param('prgid');

    return sprintf "http://imguser.pandora.tv/pandora/_channel_img_sm/%s/%s/%s/%s/vod_thumb_%s.jpg",
        substr($user, 0, 1), substr($user, 1, 1), $user, substr($prgid, -2, 2), $prgid;
}
