package Plagger::Plugin::Filter::GuessImageSize;
use strict;
use base qw( Plagger::Plugin );

use Image::Info;
use Plagger::UserAgent;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&entry,
        'update.feed.fixup'  => \&feed,
    );
}

sub entry {
    my($self, $context, $args) = @_;
    $self->fixup($context, $args->{entry}->icon);
}

sub feed {
    my($self, $context, $args) = @_;
    $self->fixup($context, $args->{feed}->image);
}

sub fixup {
    my($self, $context, $image) = @_;

    # do nothing if there's no image, or image already has width/height
    return unless $image && $image->{url};
    return if $image->{width} && $image->{height};

    $context->log(debug => "Trying to guess image size of $image->{url}");

    if ($image->{url} =~ /(\d{2,})[x_\-]+(\d{2,})\.(?:gif|png|jpe?g)/i) {
        $context->log(debug => "width=$1, height=$2");
        $image->{width}  = $1;
        $image->{height} = $2;
    }
}

sub fetch_image_info {
    my($self, $url) = @_;

    my $ua  = Plagger::UserAgent->new;
    my $res = $ua->fetch($url);

    if ($res->is_error) {
        Plagger->context->log(error => "Error fetching $url");
        return;
    }

    my $info = eval { Image::Info::image_info(\$res->content) };
    $info;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::GuessImageSize - Guess image width & height from its filenames

=head1 SYNOPSIS

  - module: Filter::GuessImageSize

=head1 DESCRIPTION

This plugin tries to guesse feed image (logo) and entry image (buddy
icon) and extracts image info like width & height based on its filenames.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
