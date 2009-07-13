package Remedie::Server::RPC::Events;
use Any::Moose;
use Remedie::PubSub;
use Coro;

BEGIN { extends 'Remedie::Server::RPC' };

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub poll {
    my($self, $req, $res) = @_;
    my $event = Remedie::PubSub->wait; # waits for the new event
    return [ $event ];
}

1;
