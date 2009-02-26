# http://www.whitehouse.gov/feed/video/
use Web::Scraper;
sub init {
    my $self = shift;
    $self->{handle} = '/video/';
}

sub needs_content { 1 }

sub find {
    my($self, $args) = @_;

    my $res = scraper {
        process 'input[name="EMBED_URL"]', code => '@value';
    }->scrape($args->{content});

    if ($res->{code}) {
        Plagger->context->current_plugin->find_enclosures(\$res->{code}, $args->{entry});
    }
}
