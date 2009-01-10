# author: Tatsuhiko Miyagawa
sub init {
    my $self = shift;
    $self->{handle} = "(flash|wmv)\.htm";
}

sub needs_content { 1 }
