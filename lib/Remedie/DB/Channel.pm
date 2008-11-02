package Remedie::DB::Channel;
use strict;
use base qw( Remedie::DB::Object );

use Remedie::DB::Channel;

use constant TYPE_FOLDER => 0;
use constant TYPE_FEED   => 1;

__PACKAGE__->meta->table('channel');
__PACKAGE__->meta->auto_initialize;
__PACKAGE__->json_encoded_columns('props');

sub items {
    my $self = shift;
    return Remedie::DB::Item::Manager->get_items(
       query => [ channel_id => $self->id ],
       sort_by => 'id DESC',
   );
}

sub count_by_status {
    my $self = shift;
    my(@status) = @_;

    return Remedie::DB::Item::Manager->get_items_count(
       query => [ channel_id => $self->id, status => \@status ],
    );
}

sub unwatched_count {
    my $self = shift;
    $self->count_by_status( Remedie::DB::Item->STATUS_NEW, Remedie::DB::Item->STATUS_DOWNLOADED );
}

sub columns_to_serialize {
    my $self = shift;
    return qw( unwatched_count );
}

package Remedie::DB::Channel::Manager;
use base qw( Remedie::DB::Manager );

sub object_class { 'Remedie::DB::Channel' }
__PACKAGE__->make_manager_methods('channels');

1;
