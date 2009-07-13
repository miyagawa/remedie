package Remedie::PubSub;
use strict;
use warnings;
use Coro;
use Coro::Channel;
use Coro::Timer;
use Coro::Signal;
use JSON::XS;

our $SWEEP_QUEUE = 60 * 60;
my(%queues, %last_access);

my $signal = Coro::Signal->new;

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
    $signal->broadcast;
}

sub wait {
    my($class, $session_id, $timeout_sec) = @_;

    $last_access{$session_id} = time;
    my $queue = ($queues{$session_id} ||= Coro::Channel->new);

    my $sweeper = async {
        my $timeout = Coro::Timer::timeout $timeout_sec;
        while (not $timeout) {
            Coro::schedule;
        }
        warn "timed out $session_id" if $ENV{REMEDIE_DEBUG};
        $signal->broadcast; # timed out: force reconnect clients
    };

    $signal->wait; # waits for new events

    my @events;
    while ($queue->size > 0) {
        push @events, $queue->get; # shouldn't block
    }
    $sweeper->cancel;

    return \@events;
}

1;
