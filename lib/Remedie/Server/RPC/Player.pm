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

    my $ua  = LWP::UserAgent->new;
    my $uri = URI->new("http://localhost:8080/requests/status.xml");
    $uri->query_form( command => 'in_play', input => $url );
    my $res = $ua->get($uri);

    if ($res->is_success) {
        return { success => 1 };
    } else {
        die "VLC is not responding. Make sure HTTP interface is enabled.";
    }
}

sub quicktime {
    my($self, $req, $res) = @_;

    my $url = $req->param('url');
    system("open", "-a", "QuickTime Player", $url);
}

1;
