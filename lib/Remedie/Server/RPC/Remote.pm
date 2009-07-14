package Remedie::Server::RPC::Remote;
use Any::Moose;

BEGIN { extends 'Remedie::Server::RPC' }
__PACKAGE__->meta->make_immutable;

no Any::Moose;

use Coro;
use Remedie::PubSub;

sub command : POST {
    my($self, $req, $res) = @_;

    async {
        Remedie::PubSub->broadcast({
            type => "command",
            command => scalar $req->param('command'),
        });
    };

    return { success => 1 };
}

1;
