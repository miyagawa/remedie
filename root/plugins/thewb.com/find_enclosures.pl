# http://www.thewb.com/shows/veronica-mars/weevils-wobble-but-they-dont-go-down/b1c93370fa
# http://www.thewb.com/shows/pop_out/b1c93370fa/1
sub init {
    my $self = shift;
    $self->{handle} = '/shows/.*?/[0-9a-f]+$|/shows/pop_out/[0-9a-f]+/';
}

sub find {
    my($self, $args) = @_;

    my $id = ($args->{url} =~ m!/([0-9a-z]+)$!)[0] || ($args->{url} =~ m!/shows/pop_out/([0-9a-z]+)/!)[0]
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://www.thewb.com/player/wbphasethree/wbvideoplayer.swf?config=wbembedplayer.xml&mediaKey=$id");
    $enclosure->type('application/x-shockwave-flash');

    return $enclosure;
}
