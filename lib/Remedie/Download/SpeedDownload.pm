package Remedie::Download::SpeedDownload;
use Moose;
extends 'Remedie::Download::Base';

use URI::filename;

use Mac::AppleScript qw(RunAppleScript);

sub run {
    my($self, $script) = @_;

    chomp $script;
    return RunAppleScript(<<SCRIPT);
tell Application "Speed Download"
$script
end tell
SCRIPT
}

sub handles { qw( http https ftp ) }


sub start_download {
    my($self, $item, $url) = @_;
    my $output_file = $item->download_path($self->conf);

    my $uid = $self->run(<<SCRIPT);
Set theFolder to POSIX file "@{[ $output_file->dir ]}"
AddURL "$url" to folder theFolder
SCRIPT

    join ":", "SpeedDownload", $uid;
}

sub track_status {
    my($self, $item, $uid) = @_;

    my $res = $self->run("GetDownloadInfo $uid");

    my $percentage;
    if ($res =~ /Finished/) {
        $percentage = 100;
    } elsif ($res =~ /(\d+) bytes of (\d+) transferred/) {
        $percentage = 100 *  $1 / $2 if $2;
    }

    return { percentage => $percentage };
}

sub cancel {
    my($self, $item, $uid) = @_;

    my $res1 = $self->run("CancelDownload $uid");
    my $res2 = $self->run("Remove $uid");
}

sub cleanup {
    my($self, $item, $uid) = @_;

    my $res  = $self->run("GetDownloadURL $uid");
    eval {
        my $file = URI->new($res)->raw_filename;
        $item->props->{download_path} = $item->download_path($self->conf)->dir->file($file)->urify;
    };
}

1;
