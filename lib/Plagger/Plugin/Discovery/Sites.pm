package Plagger::Plugin::Discovery::Sites;
use strict;
use base qw( Plagger::Plugin );

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
    $self->load_assets('pl', sub { $self->load_plugin_perl(@_) });
}

sub asset_key { 'discovery' }

sub handle {
    my($self, $context, $args) = @_;

    my $asset = $self->asset_for($args->{feed}->url, 1);
    if ($asset) {
        my $url = $asset->discover( URI->new($args->{feed}->url) );
        $args->{feed}->url($url);
        # feed URI succsessfully updated. No callback returned
    }

    return;
}

sub load_plugin_perl {
    my($self, $file, $domain) = @_;

    open my $fh, '<', $file or Plagger->context->error("$file: $!");
    (my $pkg = $domain) =~ tr/A-Za-z0-9_/_/c;
    my $plugin_class = "Plagger::Plugin::Discovery::Sites::$pkg";

    my $code = join '', <$fh>;
    unless ($code =~ /^\s*package/s) {
        $code = join "\n",
            ( "package $plugin_class;",
              "use strict;",
              "use base qw( Plagger::Plugin::Discovery::Sites::Base );",
              $code,
              "1;" );
    }

    eval $code;
    Plagger->context->error($@) if $@;

    my $plugin = $plugin_class->new($domain);
    $plugin->init;

    return $plugin;
}

package Plagger::Plugin::Discovery::Sites::Base;

sub new {
    my($class, $domain) = @_;
    bless { domain => $domain }, shift;
}

sub domain {
    $_[0]->{domain};
}

package Plagger::Plugin::Discovery::Sites;

1;
