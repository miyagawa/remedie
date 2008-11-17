package URI::filename;
use strict;
use Path::Class;

sub URI::filename {
    my $uri = shift;
    my $path = file $uri->path;
    return $path->basename;
}

1;
