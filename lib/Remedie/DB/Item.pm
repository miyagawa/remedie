package Remedie::DB::Item;
use strict;
use base qw( Remedie::DB::Object );

__PACKAGE__->meta->table('item');
__PACKAGE__->meta->auto_initialize;
__PACKAGE__->json_encoded_columns('props');

use constant TYPE_HTTP_MEDIA    => 1;
use constant TYPE_TORRENT_MEDIA => 2;
use constant TYPE_WEB_MEDIA     => 3; # Hulu etc.

use constant STATUS_NEW         => 1;
use constant STATUS_DOWNLOADING => 2;
use constant STATUS_DOWNLOADED  => 3;
use constant STATUS_WATCHED     => 4;

sub is_unwatched {
    my $self = shift;
    return $self->status == STATUS_NEW || $self->status == STATUS_DOWNLOADING || $self->status == STATUS_DOWNLOADED;
}

sub columns_to_serialize {
    return qw( is_unwatched );
}

package Remedie::DB::Item::Manager;
use base qw( Remedie::DB::Manager );

sub object_class { 'Remedie::DB::Item' }
__PACKAGE__->make_manager_methods('items');

1;
