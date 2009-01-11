package Plagger::Plugin::Discovery::Sites;
use strict;
use base qw( Plagger::Plugin );

use YAML;
use URI;
use URI::QueryParam;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'feed.discover' => \&handle,
    );
}

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->load_assets('yaml', sub { $self->load_plugin_yaml(@_) });
}

sub asset_key { 'discovery' }

sub handle {
    my($self, $context, $args) = @_;

    my $asset = $self->asset_for($args->{feed}->url, 1);
    if ($asset) {
        my $url = $asset->transform_url($args->{feed}->url);
        $args->{feed}->url($url);
        # feed URI succsessfully updated. No callback returned
    }

    return;
}

sub load_plugin_yaml {
    my($self, $file, $domain) = @_;
    my $data = YAML::LoadFile($file);

    return Plagger::Plugin::Discovery::Sites::YAML->new($data, $domain);
}

package Plagger::Plugin::Discovery::Sites::YAML;

sub new {
    my($class, $data, $domain) = @_;
    bless { %$data, domain => $domain }, $class;
}

sub domain {
    $_[0]->{domain};
}

sub transform_url {
    my($self, $url) = @_;

    my $uri = URI->new($url);

    my $feed = $self->{feed};
    $feed =~ s/{(\w+):(\w+)}/my $method = "interpolate_$1"; $self->$method($2, $uri)/eg;

    return $feed;
}

sub interpolate_match {
    my($self, $value, $uri) = @_;

    my @match = $uri->path =~ /$self->{handle}/;
    return $match[$value-1];
}

sub interpolate_query {
    my($self, $value, $uri) = @_;
    $uri->query_param($value);
}

package Plagger::Plugin::Discovery::Sites;

1;
