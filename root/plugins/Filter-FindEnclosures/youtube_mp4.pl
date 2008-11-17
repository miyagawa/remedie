# author: mizzy, yusukebe

use Plagger::Util qw( decode_content );

sub handle {
    my ($self, $url) = @_;
    $url =~ qr!http://(?:\w{2,3}\.)?youtube\.com/(?:watch(?:\.php)?)?\?v=.+!;
}

sub find {
    my ($self, $args) = @_;
    my $url = $args->{url};

    my $ua = Plagger::UserAgent->new;

    my $res = $ua->fetch($url);

    return if $res->is_error;

        if ((my $verify_url = $res->http_response->request->uri) =~ /\/verify_age\?/) {
            $res = $ua->post($verify_url, { action_confirm => 'Confirm' });
            return if $res->is_error;

            $res = $ua->fetch($url);
            return if $res->is_error;

            $args->{content} = decode_content($res);
        }

    if ($args->{content} =~ /video_id=([^&]+)&.+?&t=([^&]+)/gms){

        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url("http://www.youtube.com/get_video?video_id=$1&t=$2&fmt=18");

        $enclosure->type('video/mp4');
        $enclosure->filename("$1.mp4");
        return $enclosure;
    }

    return;
}
