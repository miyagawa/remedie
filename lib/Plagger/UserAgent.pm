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

    my $agent = $conf->{agent} || "Mozilla/5.0 (Plagger/$Plagger::VERSION http://plagger.org/)";
    my $ua = $ua_class->new(agent => $agent);

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
use AnyEvent;

$AnyEvent::HTTP::MAX_PER_HOST = 16; # :->

sub new {
    my $class = shift;
    bless {@_}, $class;
}

sub request {
    my($self, $request) = @_;

    my $headers = $request->headers;
    $headers->{'user-agent'} = $self->agent;

    warn "--> ", $request->uri if $ENV{REMEDIE_DEBUG};
    my $w = AnyEvent->condvar;
    http_request $request->method, $request->uri,
        timeout => 30, headers => $headers, sub { $w->send(@_) };
    my($data, $header) = $w->recv;
    warn "<-- ", $header->{URL}, " $header->{Status}" if $ENV{REMEDIE_DEBUG};

    return HTTP::Response->new($header->{Status}, $header->{Reason}, [ %$header ], $data);
}

1;

