# author: Tatsuhiko Miyagawa
use Remedie::JSON;

sub init {
    my $self = shift;
    $self->{domain} = "channel.pandora.tv";
    $self->{handle} = "channel/video.ptv";
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    my($json) = $args->{content} =~ /"flvInfo":({.*?})/
        or return;

    my $data = Remedie::JSON->decode($json);

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($data->{flv});
    $enclosure->type('video/x-flv');
    $enclosure->length($data->{filesize});
    # TODO use $data->{isHD}
    return $enclosure;
}
