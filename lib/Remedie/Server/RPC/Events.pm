package Remedie::Server::RPC::Events;
use Any::Moose;
use Remedie::PubSub;
use Coro;
use Coro::Timer;

BEGIN { extends 'Remedie::Server::RPC' };

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub poll {
    my($self, $req, $res) = @_;

    my $timeout = Coro::Timer::timeout(60);
    my $events  = Remedie::PubSub->wait; # waits for the new event
    return $events || [];
}

1;
