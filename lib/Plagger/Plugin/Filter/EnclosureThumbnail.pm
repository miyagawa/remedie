package Plagger::Plugin::Filter::EnclosureThumbnail;
use strict;
use base qw( Plagger::Plugin );

use Plagger::Util qw( capture_stderr );
use Path::Class;
use Path::Class::Unicode;

sub register {
    my($self, $context) = @_;

    $context->register_hook(
        $self,
        'enclosure.add' => \&filter,
        'plugin.init'   => \&initialize,
    );
}

sub initialize {
    my($self, $context, $args) = @_;
    $self->conf->{ffmpeg} ||= do {
        my @found = grep { -e "$_/ffmpeg" && -x _ }
            split(/:/, $ENV{PATH}), "/Applications/ffmpegX.app/Contents/Resources";
        @found ? $found[0] . "/ffmpeg" : "ffmpeg";
    };
    $context->log(debug => "ffmpeg is " . $self->conf->{ffmpeg});
}

sub filter {
    my($self, $context, $args) = @_;

    my $enclosure = $args->{enclosure};

    # TODO should be able to run this against downloaded file
    my $uri = URI->new($enclosure->url);
    return unless $uri->scheme eq 'file';

    # This plugin might be renamed to ::ffmpeg since we can get cover art from mp3 etc.
    return unless $enclosure->type =~ m!^video/!;

    # TODO same filename in different feeds
    my $input_file = file($uri->fullpath)->ufile;
    my $raw_filename = file($uri->raw_filename)->ufile;
    my $thumb_path = $self->conf->{thumb_dir}->file($raw_filename . ".jpg")->ufile;

    unless (-e $thumb_path) {
        $context->log(info => "Generating thumbnail for $input_file to $thumb_path");

        my $log = capture_stderr {
            my $tmpfile = $thumb_path->parent->file('tmp.jpg');

            system(
                $self->conf->{ffmpeg},
                "-i", $input_file,
                '-f'       => 'image2',
                '-pix_fmt' => 'jpg',
                '-vframes' => 1,
                '-ss'      => 3,
                '-an',
                '-deinterlace',
                $tmpfile,
            );

            rename $tmpfile => $thumb_path;
        };

        $context->log(debug => $log);
    }

    unless (-e $thumb_path) {
        $context->log( info => "Couldn't create thumbnail $thumb_path");
        return;
    }

    # TODO should be able to get width/height from ffmpeg output
    $context->log(debug => "Thumbnail set to $thumb_path");

    $thumb_path =~ s/%/%25/g;
    $thumb_path = ufile($thumb_path);
    $enclosure->thumbnail({ url => $thumb_path->uri });

    # TODO remove this
    $args->{entry}->icon({ url => $thumb_path->uri });
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::EnclosureThumbnail - Run ffmpeg to make thumbnails for local enclosure files

=head1 SYNOPSIS

  - module: Filter::EnclosureThumbnail
    config:
      thumb_dir: /path/to/thumb

=head1 DESCRIPTION

This plugin generates thumbnails for enclosures that have its own
local cache or content. You need to specify I<ffmpeg> configuration variable or
it will automatically find the binary in PATH and ffmpegX. directory on OS X.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
