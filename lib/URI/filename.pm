package URI::filename;
use strict;
use File::Basename ();
use URI::Escape ();

sub URI::filename {
    my $uri = shift;
    return File::Basename::basename($uri->path);
}

sub URI::raw_filename {
    my $uri = shift;
    my $file = URI::Escape::uri_unescape($uri->filename);
    utf8::downgrade($file);
    $file;
}

sub URI::file::fullpath {
    my $uri = shift;
    my $path = URI::Escape::uri_unescape($uri->opaque);
    utf8::downgrade($path); # handle the URI as bytes
    $path =~ s!^//!!;
    return $path;
}

1;
