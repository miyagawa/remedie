# upgrades http://www.gametrailers.com/rssgenerate.php?game1id=6364&orderby=newest&limit=20
sub init {
    my $self = shift;
    $self->{handle} = '/player/\d+.html';
}


sub find {
    my ($self, $args) = @_;

    my $uri = URI->new($args->{url});

    my($mid) = $uri->path =~ m!/(\d+)\.html! or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://www.gametrailers.com/flash/gt6player224n.swf?mid=$mid");
    $enclosure->width(480);
    $enclosure->height(392);
    $enclosure->type("application/x-shockwave-flash");
    $enclosure->thumbnail({url => "http://www.gametrailers.com/images/temp_user.jpg"});
    return $enclosure;
}

sub upgrade {
    my($self, $args) = @_;
    my $enclosure = $args->{enclosure};
    return unless $enclosure->type eq 'application/x-shockwave-flash';

    my($mid) = $args->{entry}->link =~ m!/(\d+)\.html! or return;
    if ($args->{entry}->title =~ /\sHD$/) {
        $enclosure->url("http://www.gametrailers.com/flash/gt6playerhd202k.swf?mid=$mid");
        $enclosure->width(960);
        $enclosure->height(572);
    }
}
