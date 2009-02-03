package Plagger::Plugin::CustomFeed::Scraper;
use strict;
use base qw( Plagger::Plugin );

use Plagger::Plugin::CustomFeed::Debug;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'customfeed.handle' => \&handle,
    );
}

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->load_assets('pl', sub { $self->load_plugin_perl(@_) });
}

sub asset_key { 'scraper' }

sub load_plugin_perl {
    my($self, $file, $domain) = @_;

    open my $fh, '<', $file or Plagger->context->error("$file: $!");
    (my $pkg = $domain) =~ tr/A-Za-z0-9_/_/c;
    my $plugin_class = "Plagger::Plugin::CustomFeed::Scraper::$pkg";

    my $code = join '', <$fh>;
    unless ($code =~ /^\s*package/s) {
        $code = join "\n",
            ( "package $plugin_class;",
              "use strict;",
              "use base qw( Plagger::Plugin::CustomFeed::Scraper::Base );",
              "use Web::Scraper 0.26;",
              "$code",
              "1;" );
    }

    eval $code;
    Plagger->context->error($@) if $@;

    my $plugin = $plugin_class->new($domain);
    $plugin->init;

    return $plugin;
}

sub handle {
    my($self, $context, $args) = @_;

    my $handler = $self->asset_for($args->{feed}->url);
    if ($handler) {
        $handler->scrape($self, $context, $args);
    }
}

sub update_feed {
    my($self, $context, $args, $data) = @_;

    # XXX
    local $self->{conf} = $data;
    $self->Plagger::Plugin::CustomFeed::Debug::aggregate($context, $args);
}

package Plagger::Plugin::CustomFeed::Scraper::Base;

use Encode;
use HTTP::Response::Encoding;

sub new {
    my($class, $domain) = @_;
    bless { domain => $domain }, shift;
}

sub init { }

sub domain {
    $_[0]->{domain};
}

sub build_scraper { }

sub scrape {
    my($self, $plugin, $context, $args) = @_;

    my $res = $args->{feed}->source or return;
    my $http_res = $res->http_response;

    require HTML::HeadParser;
    my $p = HTML::HeadParser->new;
    $p->parse($res->content);
    $http_res->header('Content-Type' => $p->header('Content-Type'));

    # Hack so that Scraper can get the content in a cached response
    if ($http_res->code == 304) {
        $http_res->code(200);
    }

    $http_res->content_encoding(undef); # unset gzip etc. since $res->content is decoded
    $http_res->content($res->content);

    my $scraper = $self->build_scraper or return;
    my $result = $scraper->scrape($http_res, $args->{feed}->url);
    if ($result->{entries}) {
        $plugin->update_feed($context, $args, $result);
        return 1;
    }

    return;
}

package Plagger::Plugin::CustomFeed::Scraper;

1;

__END__

=head1 NAME

Plagger::Plugin::CustomFeed::Scraper - Use Web::Scraper to scrape HTML content

=head1 SYNOPSIS

  - module: Subscription::Config
    config:
      feed:
        - url: http://www.jp.playstation.com/psworld/movie

  - module: CustomFeed::Scraper

  # jp.playstation.com/scraper.pl
  scraper {
    process ...
  };

=head1 DESCRIPTION

This plugin asllows you to write site-specific scraper using Web::Scraper.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut

