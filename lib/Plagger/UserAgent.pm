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

    my $ua = LWP::UserAgent::AnyEvent->new({ agent => "Plagger/$Plagger::VERSION (http://plagger.org/)" });

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

sub request {
    my($self, $request) = @_;

    warn "--> ", $request->uri;
    http_request $request->method, $request->uri, headers => scalar $request->headers, Coro::rouse_cb;
    my($data, $header) = Coro::rouse_wait;
    warn "<-- ", $header->{URL}, " $header->{Status}";

    return HTTP::Response->new($header->{Status}, $header->{Reason}, [ %$header ], $data);
}

1;

