use XML::LibXML::Simple qw(XMLin);

sub init {
    my $self = shift;
    $self->{handle} = '/trailers/home/xml';
}

sub handle {
    my($self, $plugin, $context, $args) = @_;

    my $res = Plagger::UserAgent->new->fetch($args->{feed}->url);
    unless ($res->is_success) {
        $context->log(error => "GET " . $args->{feed}->url . ": " . $res->status_line);
        return;
    }

    my $data = XMLin($res->content);

    my @entries;
    for my $movie (sort { $b->{info}{postdate} cmp $a->{info}{postdate} } values %{$data->{movieinfo}}) {
        push @entries, {
            title => $movie->{info}{title},
            body  => $movie->{info}{description},
            date  => $movie->{info}{postdate},
            enclosure => {
                url => $movie->{preview}{large}{content},
                length => $movie->{preview}{large}{filesize},
            },
            thumbnail => {
                url => $movie->{poster}{location},
            },
        };
    }

    return {
        title => "Apple Trailers",
        link  => $args->{feed}->url,
        entry => \@entries,
    };
}
