sub init {
    my $self = shift;
    $self->{handle} = '^/\w+$';
}

sub find {
    my ($self, $args) = @_;

    my($id) = URI->new($args->{url})->path
        or return;
    $id =~ s!^/!!;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://vid.ly/embed/$id");
    $enclosure->type('application/x-shockwave-flash');
    $enclosure->width(640);
    $enclosure->height(380);
    return $enclosure;
}

sub upgrade {
    my ($self, $args) = @_;

    my $enclosure = $args->{enclosure};
    $enclosure->url->query_param(autostart => 1);
}
