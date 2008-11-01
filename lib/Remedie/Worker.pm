package Remedie::Worker;
use strict;
use Remedie::DB::Channel;
use Remedie::DB::Item;

use DateTime;
use LWP::UserAgent;
use XML::RSS::LibXML;
use URI;

use constant NS_ITUNES  => 'http://www.itunes.com/dtds/Podcast-1.0.dtd';
use constant NS_ITUNES2 => 'http://www.itunes.com/DTDs/Podcast-1.0.dtd';
use constant NS_MEDIA   => 'http://search.yahoo.com/mrss/';

sub run {
    my $class = shift;

    my $channels = Remedie::DB::Channel::Manager->get_channels;
    for my $channel (@$channels) {
        my $uri = $channel->ident;
        warn "Updating $uri";
        my $res = LWP::UserAgent->new->get($uri);
        next if $res->is_error;

        my $feed = XML::RSS::LibXML->new;
        $feed->add_module( uri => NS_ITUNES,  prefix => 'itunes' );
        $feed->add_module( uri => NS_ITUNES2, prefix => 'itunes2' );
        $feed->add_module( uri => NS_MEDIA,   prefix => 'media' );

        $feed->parse($res->content);
        $channel->name( $feed->{channel}{title} );
        $channel->props->{description} = $feed->{channel}{description};

        if (my $image = $feed->{channel}{image}) {
            $channel->props->{thumbnail} = { url => $image->{url} }
                if $image->{url};
        }

        if (my $itunes = $feed->{channel}{itunes} || $feed->{channel}{itunes2}) {
            $channel->props->{thumbnail} = {
                url => $itunes->{image}{href},
            } if $itunes->{image};
        }

        if (my $media = $feed->{channel}{media}) {
            $channel->props->{thumbnail} = {
                url => $media->{thumbnail}{url},
            } if $media->{thumbnail};
        }

        for my $entry (@{$feed->{items}}) {
            if (my $enclosure = $entry->{enclosure}) {
                my $item = Remedie::DB::Item->new;
                $item->channel_id($channel->id);
                $item->type( Remedie::DB::Item->TYPE_HTTP_MEDIA );
                $item->ident($enclosure->{url});
                $item->name($entry->{title});
                $item->props->{size} = $enclosure->{length};
                $item->props->{type} = $enclosure->{type};
                $item->props->{link} = $entry->{link};
                $item->props->{description} = $entry->{description};

                if (my $itunes = $entry->{itunes} || $entry->{itunes2}) {
                    $item->props->{description} = $itunes->{summary}
                        if $itunes->{summary};
                }

                eval { $item->save }; # ignore dupe
                warn $@ if $@;
            }
        }
        $channel->props->{updated_on} = DateTime->now->iso8601;
        $channel->save;
    }
}

1;
