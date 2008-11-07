package Remedie::Server::RPC::Player;
use Moose;

BEGIN { extends 'Remedie::Server::RPC' }

__PACKAGE__->meta->make_immutable;

no Moose;

eval { require Mac::AppleScript };
use File::Temp;

my %map = (
    VLC => '_vlc',
    QuickTime => '_quicktime',
    iTunes => '_itunes',
);

sub play : POST {
    my($self, $req, $res) = @_;

    my $player = $req->param('player')
        or die "No player defined";

    my $p = $map{$player}
        or die "Unkown player $player";

    $self->$p($req, $res);
}

sub _vlc {
    my($self, $req, $res) = @_;
    my $url = $req->param('url');

    _run_apple_script('VLC', <<SCRIPT);
OpenURL "$url"
activate
play
next
SCRIPT

    if ($req->param('fullscreen')) {
        _run_apple_script('VLC', 'fullscreen');
    }

    return { success => 1 };
}

sub _quicktime {
    my($self, $req, $res) = @_;

    my $url = $req->param('url');
    _run_apple_script('QuickTime Player', <<SCRIPT);
activate
getURL "$url"
SCRIPT

    if ($req->param('fullscreen')) {
        _run_apple_script('QuickTime Player', 'present front movie scale screen');
    }
}

sub _run_apple_script {
    my($app, $script) = @_;

    chomp $script;
    my $as = qq(tell Application "$app"\n$script\nend tell);

    if (defined &Mac::AppleScript::RunAppleScript) {
        return Mac::AppleScript::RunAppleScript($as)
            or die "Can't launch $app via AppleScript";
    } else {
        my $temp = File::Temp->new( UNLINK => 1 );
        my $fname = $temp->filename;
        print $temp $as;
        close $temp;

        my $ret = qx(osascript $fname);
        return $ret;
    }
}

1;
