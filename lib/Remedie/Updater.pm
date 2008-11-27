package Remedie::Updater;
use strict;
use Moose;
use Remedie::DB::Channel;
use Remedie::DB::Item;
use Remedie::Log;

use Plagger;

has 'conf' => is => 'rw';

__PACKAGE__->meta->make_immutable;

no Moose;
use Path::Class;

sub update_channel {
    my($self, $channel, $opt) = @_;

    my $uri = $channel->ident;
    my $config = {
        global => {
            log => { level => 'debug' },
            plugin_path => [ dir($self->conf->{root}, "plugins")->absolute ],
            assets_path => dir($self->conf->{root})->absolute,
        },
        plugins => [
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
