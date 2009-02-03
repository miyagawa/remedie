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

    # TODO handle multiple channels. Check channel matches with feed etc.

    my $channel = $self->conf->{channel};
    my $feed    = $args->{feed};

    $channel->name( $feed->title );
    $channel->props->{link}        = $feed->link;
    $channel->props->{description} = $feed->description;

    if (my $image = $feed->image) {
        $channel->props->{thumbnail} = $image
    }

    my %found;
    for my $entry (reverse $feed->entries) {
        my $permalink = $entry->permalink || $entry->link || $entry->id or next;

        my $enclosure = $entry->primary_enclosure;
        my $ident = $enclosure ? $enclosure->url : $permalink;

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
        $item->props->{link} = $permalink;
        $item->props->{description} = $entry->summary && !$entry->summary->is_empty
           ? $entry->summary : $entry->body;
        $item->props->{updated} = $entry->date->set_time_zone('UTC')->iso8601
            if $entry->date;

        if ($enclosure && $enclosure->url) {
            if ($enclosure->type =~ m!shockwave-flash!) {
                $item->type( Remedie::DB::Item->TYPE_WEB_MEDIA );
                $item->props->{embed} = {
                    url    => $enclosure->url,
                    width  => $enclosure->width,
                    height => $enclosure->height,
                };
                $item->props->{type} = "application/x-shockwave-flash";
            } elsif ($enclosure->type =~ m!x?html!) {
                $item->type( Remedie::DB::Item->TYPE_WEB_MEDIA );
                $item->props->{embed} = { url => $enclosure->url };
                $item->props->{type}  = "text/html"; # iframe
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
            $context->log(debug => "Saving item " . $item->ident);
            eval { $item->save };
            warn $@ if $@;
        }

        $found{$ident}++;
    }

    if ($self->conf->{clear_stale}) {
        for my $item (@{ $channel->items }) {
            unless ($found{$item->ident}) {
                $context->log(info => "Removing stale entry " . $item->ident);
                $item->delete;
            }
        }
    }

    $channel->props->{updated_on} = DateTime->now->iso8601;
    $channel->save;
}

1;
