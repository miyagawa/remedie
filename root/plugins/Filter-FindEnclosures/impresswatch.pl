# author: Tatsuhiko Miyagawa
sub init {
    my $self = shift;
    $self->{domain} = "video.watch.impress.co.jp";
    $self->{handle} = "(flash|wmv)\.htm";
}

sub needs_content { 1 }
