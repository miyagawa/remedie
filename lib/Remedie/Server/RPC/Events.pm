package Remedie::Server::RPC::Events;
use Any::Moose;
use Remedie::PubSub;
use Coro;

BEGIN { extends 'Remedie::Server::RPC' };

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub poll {
    my($self, $req, $res) = @_;

    my $session = $req->param('s') || $req->header('User-Agent');
    my $events  = Remedie::PubSub->wait($session, 3 * 60); # waits for the new event
    return $events || [];
}

1;
