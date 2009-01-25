package Remedie::DB::Channel;
use strict;
use base qw( Remedie::DB::Object );

use Remedie::DB::Channel;

use constant TYPE_FOLDER => 0;
use constant TYPE_FEED   => 1;
use constant TYPE_CUSTOM => 2;

__PACKAGE__->meta->table('channel');
__PACKAGE__->meta->auto_initialize;
__PACKAGE__->json_encoded_columns('props');

sub items {
    my $self = shift;
    my %opts = @_;

    my @query = (channel_id => $self->id);
    push @query, status => $opts{status} if $opts{status} && @{$opts{status}} > 0;

    return Remedie::DB::Item::Manager->get_items(
       query => \@query,
       sort_by => 'id DESC',
       $opts{limit} ? (limit => $opts{limit}) : (),
   );
}

sub count_by_status {
    my $self = shift;
    my(@status) = @_;

    return Remedie::DB::Item::Manager->get_items_count(
        query => [ channel_id => $self->id, status => \@status ],
    );
}

sub total {
    my $self = shift;
    return Remedie::DB::Item::Manager->get_items_count(
        query => [ channel_id => $self->id ],
    );
}

sub unwatched_count {
    my $self = shift;
    $self->count_by_status( Remedie::DB::Item->STATUS_NEW, Remedie::DB::Item->STATUS_DOWNLOADED );
}

sub first_item {
    my $self = shift;

    return Remedie::DB::Item::Manager->get_items(
        query => [ channel_id => $self->id ],
        sort_by => 'id DESC',
        offset => 0, limit => 1,
    )->[0];
}

sub columns_to_serialize {
    my $self = shift;
    return qw( unwatched_count first_item total );
}

package Remedie::DB::Channel::Manager;
use base qw( Remedie::DB::Manager );

sub object_class { 'Remedie::DB::Channel' }
__PACKAGE__->make_manager_methods('channels');

1;
