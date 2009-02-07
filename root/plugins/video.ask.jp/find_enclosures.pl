sub init {
    my $self = shift;
    $self->{handle} = "/watch\.do";
}

sub find {
    my ($self, $args) = @_;

    my($id) = $args->{url} =~ m!watch\.do\?v=(.*)!
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://media.video.ask.jp/vcaster/player/decowaku_big.swf?vendor_id=c959cb7e-6549-102a-b11a-00163583b58a&video_id=$id&l=32&playDiv=e&logoFlg=Y");
    $enclosure->width(488);
    $enclosure->height(485);
    $enclosure->type('application/x-shockwave-flash');
    return $enclosure;
}
