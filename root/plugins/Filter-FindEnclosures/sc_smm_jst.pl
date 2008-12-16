# http://sc-smn.jst.go.jp/index.asp
# author: otsune
use URI;
use Web::Scraper;
sub init {
    my $self = shift;
    $self->{domain} = "sc-smn.jst.go.jp";
    $self->{handle} = "/bangumi.asp";
}

sub needs_content { 1 }

sub find {
    my ($self, $args) = @_;

    my $res = scraper {
        process "//a[contains(\@href, '.asx')]", asx_url => '@href';
        process "//img[\@width='133' and \@height='100']", thumbnail => '@src';
    }->scrape($args->{content});

    my $url = $self->find_mms_url( URI->new_abs($res->{asx_url}, $args->{url}) )
        or return;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($url);
    $enclosure->type("video/x-ms-asf");
    $enclosure->thumbnail({ url => URI->new_abs($res->{thumbnail}, $args->{url}) });
    return $enclosure;
}

sub find_mms_url {
    my ($self, $asx_url) = @_;

    my $content = Plagger->context->current_plugin->fetch_content($asx_url) or return;
    $content =~ m!<ref href="([^"]+\.wmv)"!i or return;
    return $1;
}
