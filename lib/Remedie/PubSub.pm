package Remedie::PubSub;
use strict;
use warnings;
use Coro;
use Coro::Channel;
use JSON::XS;

our $SWEEP_QUEUE = 60 * 60;
my(%queues, %last_access);

sub start_sweeper {
    AnyEvent->timer(
        after    => 5,
        interval => 60,
        cb => sub {
            for my $session (keys %queues) {
                if ($last_access{$session} < time - $SWEEP_QUEUE &&
                    $queues{$session}->size > 0) {
                    warn "PubSub $session expired" if $ENV{REMEDIE_DEBUG};
                    delete $queues{$session};
                }
            }
        },
    );
};

sub broadcast {
    my($class, $event) = @_;
    $event->{type} = delete $event->{id};
    $event = Remedie::JSON->roundtrip($event); # make it Coro-safe (I guess)
    for my $queue (values %queues) {
        $queue->put($event);
    }
}

sub wait {
    my($class, $session_id) = @_;

    $last_access{$session_id} = time;
    my $queue = ($queues{$session_id} ||= Coro::Channel->new);
    my @events = ($queue->get);


    return \@events;
}

1;
