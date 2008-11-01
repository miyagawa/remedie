package Remedie::Server::RPC::Channel;
use strict;
use base qw( Remedie::Server::RPC );

use Remedie::DB::Channel;
use Feed::Find;

sub load {
    my($self, $req, $res) = @_;
    my $channels = Remedie::DB::Channel::Manager->get_channels;
    return { channels => $channels };
}

sub create {
    my($self, $req, $res) = @_;

    my $uri = $req->param('url');

    # TODO make this pluggable
    my @feeds = Feed::Find->find($uri);
    unless (@feeds) {
        die "Can't find any feed in $uri";
    }

    my $channel = Remedie::DB::Channel->new;
    $channel->ident($feeds[0]);
    $channel->type( Remedie::DB::Channel->TYPE_FEED );
    $channel->name($feeds[0]);
    $channel->parent(0);
    $channel->save;

    return { channel => $channel };
}


1;
