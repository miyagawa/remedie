package Remedie::DB;
use strict;
use base qw( Rose::DB );

use Remedie::UserData;

my $db_path = Remedie::UserData->path_to("remedie.db");

__PACKAGE__->register_db(
    domain => "development",
    type   => "main",
    driver => "sqlite",
    database => $db_path,
);

__PACKAGE__->default_domain('development');
__PACKAGE__->default_type('main');

1;
