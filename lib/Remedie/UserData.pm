package Remedie::UserData;
use strict;
use Moose;
use Path::Class;

sub path_to {
    my($class, @path) = @_;

    ## TODO change this to something like Library/Application\ Support/Remedie
    my $base = dir($ENV{HOME}, ".remedie");
    mkdir $base, 0777 unless -e $base;

    return dir($base, @path);
}

1;
