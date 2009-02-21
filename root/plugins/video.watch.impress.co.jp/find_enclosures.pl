# author: Tatsuhiko Miyagawa
sub init {
    my $self = shift;
    $self->{handle} = '\d+_\d+\.htm';
}

sub needs_content { 1 }
