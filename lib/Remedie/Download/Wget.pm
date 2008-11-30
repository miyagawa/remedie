package Remedie::Download::Wget;
use Moose;
extends 'Remedie::Download::Base';

use Tie::File;
use URI::filename;
use Plagger::Util;
use String::ShellQuote;

sub logfile {
    my($self, $id) = @_;
    return $self->conf->{user_data}->path_to_dir("wget-logs")->file($id . ".log");
}

sub start_download {
    my($self, $item, $url) = @_;
    my $output_file = $item->download_path($self->conf);

    my $cmd = shell_quote("wget", $url, "-O", $output_file, "-o", $self->logfile($item->id), "-b");
    my $out = qx($cmd);

    my($pid) = $out =~ /pid (\d+)/;

    join ":", "Wget", $item->id, $pid;
}

sub track_status {
    my($self, $item_id, $pid) = @_;

    tie my @lines, 'Tie::File', $self->logfile($item_id)->stringify;

    my $percentage;
    for my $line (reverse @lines[-5..-1]) {
        if (defined $line && $line =~ /^\s*\d+K[ \.]+(\d+)\%/) {
            $percentage = $1;
            last;
        }
    }

    return { percentage => $percentage };
}

sub cancel {
    my($self, $item_id, $pid) = @_;

    kill 15, $pid if $pid;

    $self->cleanup($item_id);
}

sub cleanup {
    my($self, $item_id, $pid) = @_;
    $self->logfile($item_id)->remove;
}

1;
