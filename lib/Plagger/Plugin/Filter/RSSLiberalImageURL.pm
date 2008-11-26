package Plagger::Plugin::Filter::RSSLiberalImageURL;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'aggregator.filter.feed' => \&filter,
    );
}

sub filter {
    my($self, $context, $args) = @_;
    $args->{content} =~ s!<image>([^<]+)</image>!<image><url>$1</url></image>!g;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::RSSLiberalImageURL - Liberal channel image parsing on RSS 2.0

=head1 SYNOPSIS

  - module: Filter::RSSLiberalImageURL

=head1 DESCRIPTION

This plugin fixes a bad iamge/url element tree in RSS 2.0.

=head1 AUTHOR

Yasuhiro Matsumoto

=cut
