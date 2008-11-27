package URI::filename;
use strict;
use File::Basename ();
use URI::Escape ();

sub URI::filename {
    my $uri = shift;
    return File::Basename::basename($uri->path);
}

sub URI::raw_filename {
    my $url = shift;
    return URI::Escape::uri_unescape($url->filename);
}

1;
