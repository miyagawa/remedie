package Remedie::Download::Mplayer;
use Moose;
extends 'Remedie::Download::Base';

use Tie::File;
use URI::filename;
use Plagger::Util;
use String::ShellQuote;
use POSIX;

sub handles { qw( mms rtsp http ) }

sub logfile {
    my($self, $id) = @_;
    return $self->conf->{user_data}->path_to_dir("logs")->file("mplayer-${id}.log");
}

sub start_download {
    my($self, $item, $url) = @_;
    my $output_file = $item->download_path($self->conf);

    my $cmd = shell_quote("mplayer", "-dumpstream", $url, "-dumpfile", $output_file);
    $cmd =~ tr/'/"/ if $cmd !~ /"$/; # String::ShellQuote does not work on win32.
    my $log = $self->logfile($item->id);

    defined (my $pid = fork) or die "Cannot fork: $!";
    unless ($pid) {
        exec "$cmd > $log";
        die "cannnot exec $cmd: $!";
    }
    waitpid($pid, POSIX::WNOHANG);

    join ":", "Mplayer", $item->id, $pid;
}

sub track_status {
    my($self, $item, $pid) = @_;

    tie my @lines, 'Tie::File', $self->logfile($item->id)->stringify;
    my $output_file = $item->download_path($self->conf);

    my $percentage;
    for my $line (reverse @lines[-5..-1]) {
        next unless defined $line;
        if ($line =~ /Core dumped ;\)/) {
            $percentage = 100;
        }
    }

    # XXX
    if (!$percentage && -e $output_file) {
        my $size = -s _;
        my $total = 10 * 1024 * 1024;
        $percentage = 100 * $size / $total;
    }

    return { percentage => $percentage };
}

sub cancel {
    my($self, $item, $pid) = @_;

    kill 15, $pid if $pid;

    $self->logfile($item->id)->remove;
}

sub cleanup {
    my($self, $item, $pid) = @_;
    $self->logfile($item->id)->remove;
}

1;
