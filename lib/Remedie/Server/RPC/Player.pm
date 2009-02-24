package Remedie::Server::RPC::Player;
use Any::Moose;

BEGIN { extends 'Remedie::Server::RPC' }

__PACKAGE__->meta->make_immutable;

no Any::Moose;
use Path::Class;

eval { require Mac::AppleScript };
use File::Temp;
use LWP::UserAgent;
use URI::filename;

my %map = (
    VLC => '_vlc',
    QuickTime => '_quicktime',
    iTunes => '_itunes',
    Finder => '_finder',
);

my %map_inline = (
    QTL => '_qtl',
);

# XXX This needs to be pluggable
sub nicovideo : POST {
    my($self, $req, $res) = @_;

    my $uri = URI->new( $req->param('url') );
    $uri->query_form(w => $req->param('width'), h => $req->param('height'));

    my $request = HTTP::Request->new( GET => $uri );
    $request->header('Referer', "http://www.nicovideo.jp/");

    my $ua = LWP::UserAgent->new( $req->header('User-Agent') );
    my $response = $ua->request($request);
    $response->is_success or die "Request failed: " . $response->status_line;

    ## Whoa HACK
    my $code = $response->content;
    $code =~ s/document\.write\((.*?)\)/\$("#embed-player").html($1)/g;
    $code =~ s/(wv_title.*?)$/$1\n, fv_autoplay: 1, fv_new_window: true/m
        or die "This video is deleted or does not allow embeds";

    return { success => 1, code => $code };
}

sub play : POST {
    my($self, $req, $res) = @_;

    my $player = $req->param('player')
        or die "No player defined";

    my $p = $map{$player}
        or die "Unkown player $player";

    $self->$p($req, $res);
}

# Do not set :Post because of iframe :/
sub play_inline {
    my($self, $req, $res) = @_;

    my $player = $req->param('player')
        or die "No player defined";

    my $p = $map_inline{$player}
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

    return { success => 1 };
}

sub _finder {
    my($self, $req, $res) = @_;

    my $url = $req->param('url');
    my $path = URI->new($url)->fullpath;

    _run_apple_script('Finder', <<SCRIPT);
set theFile to POSIX file "$path"
reveal theFile
activate
SCRIPT

    return { success => 1 };
}

sub _qtl {
    my($self, $req, $res) = @_;

    my $url = $req->param('url');
    my $fullscreen = $req->param('fullscreen');

    my $name = URI->new($url)->filename || "play";
    $res->header('Content-Disposition', "inline; filename=$name.qtl");
    $res->content_type("application/x-quicktimeplayer");
    $res->body(<<QTL);
<?xml version="1.0"?>
<?quicktime type="application/x-quicktime-media-link"?>
<embed src="$url" autoplay="false" @{[ $fullscreen ? 'fullscreen="full"' : '' ]} quitwhendone="true" />
QTL

    return { success => 1 };
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
