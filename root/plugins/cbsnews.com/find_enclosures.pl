# author: Tatsuhiko Miyagawa
# e.g. http://feeds.cbsnews.com/CBSNewsVideoEveningNews
sub init {
    my $self = shift;
    $self->{handle} = "/video/watch/";
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    my($pid) = $args->{content} =~ /playFlashVideo\('(\w+)'\)/
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://www.cbs.com/thunder/swf30can10cbsnews/rcpHolderCbs-3-4x3.swf?releaseURL=http://release.theplatform.com/content.select?pid=$pid");
    $enclosure->type('application/x-shockwave-flash');
    $enclosure->width(425);
    $enclosure->height(324);
    return $enclosure;
}
