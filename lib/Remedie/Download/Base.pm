package Remedie::Download::Base;
use Any::Moose;

has conf => (
    is => 'rw',
);

sub download_path {
    my $self = shift;
    my($item, $url) = @_;

    return $self->conf->{user_data}->path_to_dir("videos", $item->id)->file( URI->new($url)->raw_filename );
}

1;
