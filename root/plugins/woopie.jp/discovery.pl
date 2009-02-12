use URI;
use Remedie::JSON;

sub init {
    my $self = shift;
    $self->{handle} = '/channel/watch/\d+';
}

sub handle {
    my ( $self, $plugin, $context, $args ) = @_;
    my($channel_id) = $args->{feed}->url =~ m!channel/watch/(\d+)!;
    my $api_url = URI->new("http://www.woopie.jp/api/getChannelVideos");
    $api_url->query_form( { id => $channel_id, count => 99, start => 0 } );

    my $res = Plagger::UserAgent->new->fetch($api_url);
    unless ( $res->is_success ) {
        $context->log( error => "GET channel: $channel_id failed: "
              . $res->http_response->status_line );
        return;
    }

    my $data = Remedie::JSON->decode( $res->content );
    my @entries;
    for my $video (@$data) {
        my $entry = {
            title       => $video->{title},
            author      => $video->{author},
            body        => $video->{content},
            link        => $video->{surl},
            "enclosure" => { "thumbnail" => { url => $video->{purl} }, },
        };
	push( @entries, $entry );
    }

    return {
	title => "woopie.jp channel: $channel_id",
        link  => $args->{feed}->url,
        entry => \@entries,
    };
}

