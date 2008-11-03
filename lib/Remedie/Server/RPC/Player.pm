package Remedie::Server::RPC::Player;
use Moose;

BEGIN { extends 'Remedie::Server::RPC' }

__PACKAGE__->meta->make_immutable;

no Moose;

eval { require Mac::AppleScript };

my %map = (
    VLC => '_vlc',
    QuickTime => '_quicktime',
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

    _run_apple_script(<<SCRIPT) or die "Can't launch VLC with AppleScript";
tell application "VLC"
  OpenURL "$url"
  activate
  fullscreen
  play
  next
end tell
SCRIPT

    return 1;
}

sub _quicktime {
    my($self, $req, $res) = @_;

    my $url = $req->param('url');
    system("open", "-a", "QuickTime Player", $url);
}

sub _run_apple_script {
    my $script = shift;

    if (defined &Mac::AppleScript::RunAppleScript) {
        return Mac::AppleScript::RunAppleScript($script);
    } else {
        open my $fh, " osascript" or die "Can't launch osascript: $!";
        print $fh $script;
        close $fh
    }
}

1;
