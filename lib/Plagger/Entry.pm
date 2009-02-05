package Plagger::Entry;
use strict;

use base qw( Plagger::Thing );
__PACKAGE__->mk_accessors(qw( tags link feed_link rate meta source language ));
__PACKAGE__->mk_text_accessors(qw( title author summary body ));
__PACKAGE__->mk_date_accessors(qw( date ));

*icon = sub { shift->thumbnail(@_) };

use Digest::MD5;
use DateTime::Format::Mail;
use Storable;
use Plagger::Util;
use List::Util qw( first );

sub new {
    my $class = shift;
    bless {
        rate    => 0,
        widgets => [],
        tags    => [],
        meta    => {},
        enclosures => [],
    }, $class;
}

sub add_rate {
    my($self, $rate) = @_;
    $self->rate( $self->rate + $rate );
}

sub text {
    my $self = shift;
    join "\n", $self->link, $self->title, $self->body;
}

sub add_widget {
    my($self, $widget) = @_;
    push @{ $self->{widgets} }, $widget;
}

sub widgets {
    my $self = shift;
    wantarray ? @{ $self->{widgets} } : $self->{widgets};
}

sub permalink {
    my $self = shift;
    $self->{permalink} = shift if @_;
    $self->{permalink} || $self->link;
}

sub id {
    my $self = shift;
    $self->{id} = shift if @_;
    $self->{id} || $self->permalink || do {
        my $id = $self->feed_link;
        $id .= $self->date ? $self->date->epoch : $self->title;
        $id;
    };
}

sub id_safe {
    my $self = shift;
    Plagger::Util::safe_id($self->id);
}

sub title_text {
    my $self = shift;
    $self->title ? $self->title->plaintext : undef;
}

sub body_text {
    my $self = shift;
    $self->body ? $self->body->plaintext : undef;
}

sub add_enclosure {
    my($self, $enclosure) = @_;

    # don't add enclosure with the same URL again and again
    unless ($enclosure->url && grep { $_->url && $_->url eq $enclosure->url } $self->enclosures) {
        Plagger->context->run_hook('enclosure.add', { entry => $self, enclosure => $enclosure });
        if ($enclosure->thumbnail_or_image) {
            $self->icon($enclosure->thumbnail_or_image);
        }
        push @{ $self->{enclosures} }, $enclosure;
    }
}

sub enclosure {
    my $self = shift;
    wantarray ? @{$self->{enclosures}} : $self->{enclosures}->[0];
}

sub primary_enclosure {
    my $self = shift;
    my @enclosures = $self->enclosures;
    # XXX 'html' means iframe embed. Should we use more specific something else?
    my $primary = first { $_->type =~ /video|audio|shockwave-flash|html/ } @enclosures;
    return $primary || $self->enclosure;
}

sub enclosures {
    my $self = shift;
    wantarray ? @{$self->{enclosures}} : $self->{enclosures};
}

sub has_enclosure {
    my $self = shift;
    scalar @{$self->{enclosures}} > 0;
}

sub digest {
    my $self = shift;
    my $data = $self->title . ($self->body || '');
    Encode::_utf8_off($data);
    Digest::MD5::md5_hex($data);
}

1;
