package Remedie::Server::RPC::Remote;
use Any::Moose;

BEGIN { extends 'Remedie::Server::RPC' }
__PACKAGE__->meta->make_immutable;

no Any::Moose;

use Coro;
use Remedie::DB::Channel;
use Remedie::DB::Item;
use Remedie::PubSub;

sub move : POST {
    my($self, $req, $res) = @_;

    my $channel_id = $req->param('channel_id');
    async {
        Remedie::PubSub->broadcast({
            type => "command",
            command => "remedie.showChannel(remedie.channels[$channel_id])",
        });
    };

    return { success => 1 };
}

sub play : POST {
    my($self, $req, $res) = @_;

    my $channel = Remedie::DB::Channel->new(id => $req->param('channel_id'))->load;
    my $item = Remedie::DB::Item->new(id => $req->param('item_id'))->load;

    async {
        Remedie::PubSub->broadcast({
            type => "command",
            command => sprintf("remedie.openAndPlay(%d, %d)", $channel->id, $item->id),
        });
    };

    return { success => 1 };
}

1;
