package Remedie::PubSub;
use strict;
use warnings;
use Coro::Channel;
use JSON::XS;

my $queue = Coro::Channel->new;

sub broadcast {
    my($class, $event) = @_;
    $event->{type} = delete $event->{id};
    $event = Remedie::JSON->roundtrip($event); # make it Coro-safe (I guess)
    $queue->put($event);
}

sub wait {
    my $class = shift;
    my @events = ($queue->get);
    return \@events;
}

1;
