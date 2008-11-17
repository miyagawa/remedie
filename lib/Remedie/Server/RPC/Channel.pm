package Remedie::Server::RPC::Channel;
use Moose;
use Remedie::DB::Channel;
use Remedie::Updater;
use Feed::Find;

BEGIN { extends 'Remedie::Server::RPC' };

__PACKAGE__->meta->make_immutable;

no Moose;

sub load {
    my($self, $req, $res) = @_;
    my $channels = Remedie::DB::Channel::Manager->get_channels;
    return { channels => $channels };
}

sub create : POST {
    my($self, $req, $res) = @_;

    my $uri = $req->param('url');

    # TODO make this pluggable
    $uri = normalize_uri($uri);
    warn $uri;
    my @feeds = Feed::Find->find($uri);

    my $type = $feeds[0] ? Remedie::DB::Channel->TYPE_FEED : Remedie::DB::Channel->TYPE_CUSTOM;
    my $channel_uri = $feeds[0] || $uri;

    # TODO maybe prompt or ask plugin if $type is CUSTOM

    my $channel = Remedie::DB::Channel->new;
    $channel->ident($channel_uri);
    $channel->type($type);
    $channel->name($channel_uri);
    $channel->parent(0);
    $channel->save;

    return { channel => $channel };
}

sub refresh : POST {
    my($self, $req, $res) = @_;

    my $channel = Remedie::DB::Channel->new( id => $req->param('id') )->load;
    Remedie::Updater->new( conf => $self->conf )->update_channel($channel)
        or die "Refreshing failed";

    $channel->load; # reload

    return { success => 1, channel => $channel };
}

sub show {
    my($self, $req, $res) = @_;

    my $channel = Remedie::DB::Channel->new( id => $req->param('id') )->load;

    return {
        channel => $channel,
        items   => $channel->items,
    };
}

sub update_status : POST {
    my($self, $req, $res) = @_;

    my $id      = $req->param('id');
    my $item_id = $req->param('item_id');
    my $status  = $req->param('status');

    my $enum = do {
        my $meth = "STATUS_" . uc $status;
        Remedie::DB::Item->$meth;
    };

    my $items;
    if ($id) {
        my $channel = Remedie::DB::Channel->new( id => $id )->load;
        $items = $channel->items;
    } else {
        my $item = Remedie::DB::Item->new( id => $item_id )->load;
        $id    = $item->channel_id;
        $items = [ $item ];
    }

    for my $item (@$items) {
        $item->status($enum);
        $item->save;
    }

    my $channel = Remedie::DB::Channel->new( id => $id )->load;
    return { channel => $channel, success => 1 };
}

sub normalize_uri {
    my $uri = shift;
    $uri =~ s/^feed:/http:/;
    $uri = "http://$uri" unless $uri =~ m!^https?://!;

    return URI->new($uri)->canonical;
}


sub remove : POST {
    my($self, $req, $res) = @_;

    my $id      = $req->param('id');
    my $channel = Remedie::DB::Channel->new( id => $id )->load;
    my $items   = $channel->items;

    $channel->delete;

    # TODO remove local files if downloaded (optional)
    for my $item (@$items) {
        $item->delete;
    }

    return { success => 1, id => $id };
}


1;
