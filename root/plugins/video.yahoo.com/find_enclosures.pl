# author: Tatsuhiko Miyagawa
sub init {
    my $self = shift;
    $self->{handle} = '/watch/\d+/\d+';
}

sub needs_content { 1 }

# extract from link rel="video_src" etc. which is done in FindEnclosures.pm


