# http://www.flog.jp/index.rdf

sub init {
    my $self = shift;
    $self->{handle} = '/comment\.php/\d+';
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    my ($link) = $args->{content} =~ m!/j\.php/(http://[^">\s]+)!
        or return;

    Plagger->context->current_plugin->add_enclosure($args->{entry}, [ 'a', { href => $link } ], 'href');
}
