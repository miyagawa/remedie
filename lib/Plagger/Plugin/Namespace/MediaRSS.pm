package Plagger::Plugin::Namespace::MediaRSS;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'aggregator.feed.fixup' => \&handle_feed,
        'aggregator.entry.fixup' => \&handle,
    );
}

sub handle_feed {
    my($self, $context, $args) = @_;

    for my $ns ("http://search.yahoo.com/mrss", "http://search.yahoo.com/mrss/") {
        my $media;
        if ($args->{orig_feed}{rss}{channel} and $media = $args->{orig_feed}{rss}{channel}{$ns}) {
            if ($media->{thumbnail}) {
                $args->{feed}->image({
                    url    => $media->{thumbnail}->{url},
                    width  => $media->{thumbnail}->{width},
                    height => $media->{thumbnail}->{height},
                });
            }
        }
    }
}

sub handle {
    my($self, $context, $args) = @_;

    # Ick, I need to try the URL with and without the trailing slash
    for my $media_ns ("http://search.yahoo.com/mrss", "http://search.yahoo.com/mrss/") {
        my $media = $args->{orig_entry}->{entry}->{$media_ns}->{group} || $args->{orig_entry}->{entry};

        my $content = $media->{$media_ns}{content} || $media->{$media_ns} || [];
        $content = [ $content ] unless ref $content && ref $content eq 'ARRAY';

        for my $media_content (@{$content}) {
            $media_content = $media_content->{$media_ns}
                if $media_content->{$media_ns};

            if ($media_content->{url}) {
                $context->log(debug => "Found MediaRSS $media_content->{url}");
                my $enclosure = Plagger::Enclosure->new;
                $enclosure->url( URI->new($media_content->{url}) );
                $enclosure->type($media_content->{type});
                $args->{entry}->add_enclosure($enclosure);
            }
        }

        if (my $thumbnail = $media->{$media_ns}{thumbnail} || $media->{$media_ns}{content}{$media_ns}{thumbnail}) {
            $context->log(debug => "Found MediaRSS thumb $thumbnail->{url}");
            $args->{entry}->icon({
                url   => $thumbnail->{url},
                width => $thumbnail->{width},
                height => $thumbnail->{height},
            });
        }

        # media:player
        if (my $player = $media->{$media_ns}{player}) {
            if ($player->{url}) {
                $context->log(debug => "Found media:player $player->{url}");
                my $enclosure = Plagger::Enclosure->new;
                $enclosure->url($player->{url});
                $enclosure->type("application/x-shockwave-flash"); # hopefully
                for my $attr (qw( width height )) {
                    $enclosure->$attr($player->{$attr}) if $player->{$attr};
                }
                $args->{entry}->add_enclosure($enclosure);
            }
        }
    }

    1;
}

1;
__END__

=head1 NAME

Plagger::Plugin::Namespace::MediaRSS - Media RSS extension

=head1 SYNOPSIS

  - module: Namespace::MediaRSS

=head1 DESCRIPTION

This plugin parses Media RSS extension in the feeds and stores media
information to entry enclosures. This plugin is loaded by default.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://search.yahoo.com/mrss>

=cut
