package Remedie::Download::Wget;
use Moose;
extends 'Remedie::Download::Base';

use Tie::File;
use URI::filename;

sub logfile {
    my($self, $id) = @_;
    return $self->conf->{user_data}->path_to_dir("wget-logs")->file($id . ".log");
}

sub start_download {
    my($self, $item, $url) = @_;
    my $output_file = $item->download_path($self->conf);
    system("wget", $url, "-O", $output_file, "-o", $self->logfile($item->id), "-b");
    return "Wget:" . $item->id;
}

sub track_status {
    my($self, $item_id) = @_;

    tie my @lines, 'Tie::File', $self->logfile($item_id)->stringify;

    my $percentage;
    for my $line (reverse @lines[-5..-1]) {
        if (defined $line && $line =~ /(\d+)\%/) {
            $percentage = $1;
            if ($percentage == 100) {
                my $item = Remedie::DB::Item->new(id => $item_id)->load;
                delete $item->props->{track_id};
                $item->save;
            }
            last;
        }
    }

    return { percentage => $percentage };
}

1;
