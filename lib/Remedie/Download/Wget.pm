package Remedie::Download::Wget;
use Moose;
extends 'Remedie::Download::Base';

use Tie::File;
use URI::filename;
use Plagger::Util;
use String::ShellQuote;
use POSIX;

sub handles { qw( http https ftp ) }

sub logfile {
    my($self, $id) = @_;
    return $self->conf->{user_data}->path_to_dir("logs")->file("wget-${id}.log");
}

sub start_download {
    my($self, $item, $url) = @_;
    my $output_file = $item->download_path($self->conf);

    my $pid;

    if ($^O ne "MSWin32") {
        my $cmd = shell_quote("wget", $url, "-O", $output_file, "-o", $self->logfile($item->id), "-b");
        my $out = qx($cmd);
        $pid = $out =~ /pid (\d+)/;
    } else {
        my $cmd = shell_quote("wget", $url, "-O", $output_file, "-o", $self->logfile($item->id));
        $cmd =~ tr/'/"/ if $cmd !~ /"$/; # String::ShellQuote does not work on win32.
        defined ($pid = fork) or die "Cannot fork: $!";
        unless ($pid) {
            exec $cmd;
            die "cannnot exec $cmd: $!";
        }
        waitpid($pid, POSIX::WNOHANG);
    }

    join ":", "Wget", $pid;
}

sub track_status {
    my($self, $item, $pid) = @_;

    tie my @lines, 'Tie::File', $self->logfile($item->id)->stringify;

    my $status = {};
    for my $line (reverse @lines[-5..-1]) {
        next unless defined $line;
        if ($line =~ /^\s*\d+K[ \.]+(\d+)\%/) {
            $status->{percentage} = $1;
            last;
        } elsif ($line =~ /Unsupported scheme|ERROR [45]/) {
            $status->{error} = $line;
            last;
        }
    }

    return $status;
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
