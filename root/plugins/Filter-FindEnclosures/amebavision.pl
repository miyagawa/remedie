sub init {
    my $self = shift;
    $self->{domain} = "vision.ameba.jp";
    $self->{handle} = "watch.do";
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    my($id, $jpg) = $args->{content} =~ m!Paste\.init\('\d+','(.*?)','(http://.*?\.jpg)'\)!
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://vm1-1.vision.ameba.jp/mcb.swf?id=$id");
    $enclosure->type('application/x-shockwave-flash');
    $enclosure->thumbnail({ url => $jpg });
    return $enclosure;
}

sub upgrade {
    my($self, $args) = @_;

    my $enclosure = $args->{enclosure};
    return unless $enclosure->type eq 'application/x-shockwave-flash';

    my $id = URI->new($enclosure->url)->query_param('id')
        or return;

    $enclosure->url("http://vm1-1.vision.ameba.jp/mcb.swf?id=$id&width=680&height=510");
    $enclosure->width(680);
    $enclosure->height(510);
}
