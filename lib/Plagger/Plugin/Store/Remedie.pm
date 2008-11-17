package Plagger::Plugin::Store::Remedie;
use strict;
use warnings;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook( $self, 'publish.feed' => \&store );
}

sub store {
    my($self, $context, $args) = @_;

    my $channel = $self->conf->{channel};
    my $feed    = $args->{feed};

    $channel->name( $feed->title );
    $channel->props->{link}        = $feed->link;
    $channel->props->{description} = $feed->description;

    if (my $image = $feed->image) {
        $channel->props->{thumbnail} = $image
    }

    for my $entry (reverse $feed->entries) {
        my $enclosure = $entry->enclosure;
        my $ident = $enclosure ? $enclosure->url : $entry->link;

        my $item = Remedie::DB::Item::Manager->lookup(
            channel_id => $channel->id,
            ident      => "$ident", # stringification
        );

        unless ($item) {
            $item = Remedie::DB::Item->new;
            $item->channel_id($channel->id);
            $item->ident($ident);
            $item->status( Remedie::DB::Item->STATUS_NEW );
        }

        $item->name($entry->title);
        $item->props->{link} = $entry->link;
        $item->props->{description} = $entry->summary && !$entry->summary->is_empty
           ? $entry->summary : $entry->body;
        $item->props->{updated} = $entry->date->set_time_zone('UTC')->iso8601
            if $entry->date;

        if ($enclosure && $enclosure->url) {
            if ($enclosure->type =~ m!text/html!) {
                $item->type( Remedie::DB::Item->TYPE_WEB_MEDIA );
                $item->props->{embed} = {
                    url => $enclosure->url,
                    width => $enclosure->width,
                    height => $enclosure->height,
                };
#            } elsif ($enclosure->type =~ m!torrent!) {
            } else {
                $item->type( Remedie::DB::Item->TYPE_HTTP_MEDIA );
                $item->props->{size} = $enclosure->length;
                $item->props->{type} = $enclosure->type;
            }
        }

        if ($entry->icon) {
            $item->props->{thumbnail} = $entry->icon;
        }

        if ($item->type) {
            eval { $item->save };
            warn $@ if $@;
        }
    }

    $channel->props->{updated_on} = DateTime->now->iso8601;
    $channel->save;
}

1;
