package Remedie::Server::RPC::Channel;
use strict;
use base qw( Remedie::Server::RPC );

use Remedie::DB::Channel;
use Remedie::Worker;
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
    $uri = normalize_uri($uri);
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

    ## TODO make it async
    Remedie::Worker->work_channel($channel);

    return { channel => $channel };
}

sub normalize_uri {
    my $uri = shift;
    $uri =~ s/^feed:/http:/;
    $uri = "http://$uri" unless $uri =~ m!^https?://!;

    return URI->new($uri)->canonical;
}

1;
