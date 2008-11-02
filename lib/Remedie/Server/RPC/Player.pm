package Remedie::Server::RPC::Player;
use strict;
use base qw( Remedie::Server::RPC );

use LWP::UserAgent;

my %map = (
    VLC => 'vlc',
    QuickTime => 'quicktime',
);

sub play {
    my($self, $req, $res) = @_;

    my $player = $req->param('player')
        or die "No player defined";

    my $p = $map{$player}
        or die "Unkown player $player";

    $self->$p($req, $res);
}

sub vlc {
    my($self, $req, $res) = @_;

    my $url = $req->param('url');

    system("open", "-a", "VLC");

    $self->_run_vlc( command => 'pl_empty' );
    $self->_run_vlc( command => 'in_play', input => $url );

    system("open", "-a", "VLC"); # make it foreground

    return { success => 1 };
}

sub _run_vlc {
    my $slef = shift;

    my $ua  = LWP::UserAgent->new;
    my $uri = URI->new("http://localhost:8080/requests/status.xml");
    $uri->query_form(@_);
    my $res = $ua->get($uri);
    $res->is_success
        or die "VLC is not responding. Make sure VLC is running and HTTP interface is enabled.";

    return $res;
}

sub quicktime {
    my($self, $req, $res) = @_;

    my $url = $req->param('url');
    system("open", "-a", "QuickTime Player", $url);
}

1;
