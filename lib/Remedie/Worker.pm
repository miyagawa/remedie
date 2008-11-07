package Remedie::Worker;
use Moose;
use Remedie::DB::Channel;
use Remedie::DB::Item;
use Remedie::Log;

use DateTime;
use LWP::UserAgent;
use XML::RSS::LibXML;
use URI;

has 'channels' => (
    is => 'rw',
    isa => 'ArrayRef',
    auto_deref => 1,
    lazy => 1,
    builder => 'build_default_channels',
);

__PACKAGE__->meta->make_immutable;

no Moose;

use constant NS_ITUNES  => 'http://www.itunes.com/dtds/Podcast-1.0.dtd';
use constant NS_ITUNES2 => 'http://www.itunes.com/DTDs/Podcast-1.0.dtd';
use constant NS_MEDIA   => 'http://search.yahoo.com/mrss/';

sub build_default_channels { Remedie::DB::Channel::Manager->get_channels }

sub run {
    my $self = shift;

    my $channels = $self->channels;
    for my $channel (@$channels) {
        eval { $self->work_channel($channel) };
        WARN $@ if $@;
    }
}

sub work_channel {
    my($self, $channel) = @_;

    my $uri = $channel->ident;
    warn "Updating $uri";
    my $res = LWP::UserAgent->new(timeout => 15)->get($uri);
    return if $res->is_error;

    my $feed = XML::RSS::LibXML->new;

    $feed->parse($res->content);
    $channel->name( $feed->{channel}{title} );
    $channel->props->{link}        = $feed->{channel}{link};
    $channel->props->{description} = $feed->{channel}{description};

    if (my $image = $feed->{channel}{image}) {
        $channel->props->{thumbnail} = { url => $image->{url} }
            if $image->{url};
    }

    if (my $itunes = $feed->{channel}{+NS_ITUNES} || $feed->{channel}{+NS_ITUNES2}) {
        $channel->props->{thumbnail} = {
            url => $itunes->{image}{href},
        } if $itunes->{image};
    }

    if (my $media = $feed->{channel}{+NS_MEDIA}) {
        $channel->props->{thumbnail} = {
            url => $media->{thumbnail}{url},
        } if $media->{thumbnail};
    }

    for my $entry (reverse @{$feed->{items}}) {
        if (my $enclosure = $entry->{enclosure}) {
            my $item = Remedie::DB::Item::Manager->lookup(
                channel_id => $channel->id,
                ident      => $enclosure->{url},
            );

            unless ($item) {
                $item = Remedie::DB::Item->new;
                $item->channel_id($channel->id);
                $item->ident($enclosure->{url});
                $item->status( Remedie::DB::Item->STATUS_NEW );
            }

            $item->type( Remedie::DB::Item->TYPE_HTTP_MEDIA );
            $item->name($entry->{title});
            $item->props->{size} = $enclosure->{length};
            $item->props->{type} = $enclosure->{type};
            $item->props->{link} = $entry->{link};
            $item->props->{description} = $entry->{description};
            $item->props->{updated} = $entry->{pubDate} || $entry->{dc}{date};

            if (my $itunes = $entry->{+NS_ITUNES} || $entry->{+NS_ITUNES2}) {
                for my $field (qw( subtitle summary )) {
                    if ($itunes->{$field}) {
                        $item->props->{description} = $itunes->{$field};
                        last;
                    }
                }
            }

            if (my $media = $entry->{+NS_MEDIA}) {
                $media = $media->{content}{+NS_MEDIA}
                    if exists $media->{content}{+NS_MEDIA};
                $item->props->{thumbnail} = {
                    url => $media->{thumbnail}{url},
                } if $media->{thumbnail}{url};
            }

            eval { $item->save };
            warn $@ if $@;
        }
    }

    $channel->props->{updated_on} = DateTime->now->iso8601;
    $channel->save;

    return 1;
}

1;
