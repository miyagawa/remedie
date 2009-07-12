package Plagger::UserAgent;
use strict;

use Carp;
use Plagger::Cookies;
use URI::Fetch 0.06;

sub new {
    my $class = shift;

    my $self = bless {}, $class;
    $self;
}

sub fetch {
    my($self, $url, $plugin, $opt) = @_;

    my $conf = Plagger->context ? Plagger->context->conf->{user_agent} : {};

    my $ua_class = URI->new($url)->scheme =~ /^https?$/
        ? "LWP::UserAgent::AnyEvent" : "LWP::UserAgent";
    my $ua = $ua_class->new( $conf->{agent} || "Mozilla/5.0 (Plagger/$Plagger::VERSION http://plagger.org/)" );

    my $res = URI::Fetch->fetch($url,
        UserAgent => $ua,
        $plugin ? (Cache => $plugin->cache) : (),
        ForceResponse => 1,
        ($opt ? %$opt : ()),
    );

    if ($res && $url =~ m!^file://!) {
        $res->content_type( Plagger::Util::mime_type_of(URI->new($url)) );
    }

    $res;
}

package LWP::UserAgent::AnyEvent;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw( agent timeout ));

use AnyEvent::HTTP;
use Coro;

sub new {
    my $class = shift;
    my($agent) = @_;

    my $self = bless {}, $class;
    $self->agent($agent) if $agent;

    return $self;
}

sub request {
    my($self, $request) = @_;

    my $headers = $request->headers;
    $headers->{'user-agent'} = $self->agent;

    warn "--> ", $request->uri if $ENV{REMEDIE_DEBUG};
    my $cb = Coro::rouse_cb;
    http_request $request->method, $request->uri,
        timeout => 30, headers => $headers, $cb;
    my($data, $header) = Coro::rouse_wait($cb);
    warn "<-- ", $header->{URL}, " $header->{Status}" if $ENV{REMEDIE_DEBUG};

    return HTTP::Response->new($header->{Status}, $header->{Reason}, [ %$header ], $data);
}

1;

