package Path::Class::URIfy;
use strict;
use URI::filename;
my $fs_encoding;

sub fs_encoding {
    $fs_encoding ||= do {
        my $enc = 'utf-8';
        eval {
            require 'Win32/API.pm';
            Win32::API->Import('kernel32', 'UINT GetACP()');
            $enc = 'cp'.GetACP();
        } if $^O eq "MSWin32";
        $enc;
    }
}

sub Path::Class::Entity::urify {
    my $self = shift;

    my $path = $self->stringify;
    $path =~ s!\\!/!g if $^O eq "MSWin32";

    my $unicode = Encode::decode(fs_encoding(), $path);
    $unicode =~ s/%/%25/g;

    return URI->new("file://$unicode");
}

1;
