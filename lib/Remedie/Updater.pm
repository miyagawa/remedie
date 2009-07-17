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

# producer
sub queue_channel {
    my $class = shift;
    $queue->put([ @_ ]); # $event_id, $channel_id, $conf, $opts
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
    my($event_id, $channel_id, $conf, $opts) = @$job;

    my $updater = $class->new( conf => $conf );
    my $channel = Remedie::DB::Channel->new(id => $channel_id)->load;

    $updater->update_channel($channel, $opts)
        or die "Refreshing failed";

    $channel->load; # reload

    Remedie::PubSub->broadcast({ id => $event_id, success => 1, channel => $channel });
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

    Plagger->bootstrap(config => $config);

    return 1;
}

1;
