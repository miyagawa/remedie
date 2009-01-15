sub init {
    my $self = shift;
    $self->{handle} = ".";
}


sub find {
    my ($self, $args) = @_;
    my $uri = URI->new($args->{url});
    my($video_id) = $uri->path =~ m!/(\w+)!
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://www.joost.com/embed/$video_id");
    $enclosure->type('application/x-shockwave-flash');
    return $enclosure;
}

sub upgrade {
    my ($self, $args) = @_;
    my($self, $args) = @_;

    my $enclosure = $args->{enclosure};
    return unless $enclosure->type eq 'application/x-shockwave-flash';

    my($video_id) = $enclosure->url =~ m!/embed/([\w\-]+)!
        or return;

    $enclosure->url("http://www.joost.com/embed/$video_id?autoplay=1");
}

