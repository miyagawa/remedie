package Remedie::Worker;
use strict;
use Remedie::DB::Channel;

use DateTime;
use XML::Feed;
use URI;

sub run {
    my $class = shift;

    my $channels = Remedie::DB::Channel::Manager->get_channels;
    for my $channel (@$channels) {
        my $uri = $channel->ident;
        my $feed = XML::Feed->parse( URI->new($uri) );
        $channel->name( $feed->title );
        $channel->props->{updated_on} = DateTime->now->iso8601;
        $channel->save;
    }
}

1;
