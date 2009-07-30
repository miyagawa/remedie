package Remedie::Updater;
use strict;
use Any::Moose;
use Remedie::DB::Channel;
use Remedie::DB::Item;
use Remedie::Log;
use Remedie::PubSub;

use Plagger;

has 'conf' => is => 'rw';

__PACKAGE__->meta->make_immutable;

no Any::Moose;
use Path::Class;
use Coro;
use Coro::Channel;

my $queue = Coro::Channel->new;

sub start_periodic_updater {
    my($class, $conf) = @_;

    my $w; $w = AnyEvent->timer(
        after => 15 * 60,
        interval => 60 * 60,
        cb => sub {
            scalar $w;
            $class->update_all($conf);
        },
    );
}

sub update_all {
    my($class, $conf) = @_;

    my $channels = Remedie::DB::Channel::Manager->get_channels;
    my @events;
    for my $channel (@$channels) {
        async { Remedie::Updater->queue_channel($channel->id, $conf) };
        push @events, {
            type => 'trigger_event',
            event => 'remedie-channel-refresh-started',
            channel_id => $channel->id,
        };
    }

    async { Remedie::PubSub->broadcast(@events) };
}

# producer
sub queue_channel {
    my $class = shift;
    $queue->put([ @_ ]); # $channel_id, $conf, $opts
}

sub start_workers {
    my($class, $number) = @_;

    for (1..$number) {
        async {
            Remedie::Updater->work_channel while 1;
        };
    }
}

sub work_channel {
    my $class = shift;

    my $job = $queue->get; # blocks
    my($channel_id, $conf, $opts) = @$job;

    my $updater = $class->new( conf => $conf );
    my $channel = Remedie::DB::Channel->new(id => $channel_id)->load;

    $updater->update_channel($channel, $opts)
        or die "Refreshing failed";

    $channel->load; # reload

    Remedie::PubSub->broadcast({
        type => 'trigger_event',
        event => 'remedie-channel-updated',
        channel => $channel,
    });
}

sub update_channel {
    my($self, $channel, $opt) = @_;

    my $uri = $channel->ident;
    my $config = {
        global => {
            log => { level => 'debug' },
            plugin_path => [ dir($self->conf->{root}, "plugins")->absolute ],
            assets_path => dir($self->conf->{root})->absolute,
            user_agent  => { agent => "Mozilla/5.0 (Remedie/$Remedie::VERSION)" },
        },
        plugins => [
            { module => "Aggregator::Simple",
              config => { no_discovery => 1 } },
            { module => "Bundle::Defaults" },
            { module => "Bundle::Remedie",
              config => $self->conf },
            { module => "Subscription::Config",
              config => { feed => [ $uri ] } },
            { module => "Store::Remedie",
              config => { channel => $channel, clear_stale => $opt->{clear_stale} } },
        ],
    };

    DB::enable_profile() if $ENV{NYTPROF};
    Plagger->bootstrap(config => $config);
    DB::finish_profile() if $ENV{NYTPROF};

    return 1;
}

1;
