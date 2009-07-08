package HTTP::Engine::Interface::POE;
our $CLIENT; ## no critic
use Any::Moose;
use HTTP::Engine::Interface
    builder => 'NoEnv',
    writer  =>  {
        response_line => 1,
        'write' => sub {
            my ($self, $buffer) = @_;
            $CLIENT->put($buffer);
            return 1;
        }
    }
;

use POE qw/
    Component::Server::TCP
    Filter::HTTPD
/;
use URI::WithBase;

has host => (
    is      => 'ro',
    isa     => 'Str',
    default => '127.0.0.1',
    trigger  => sub {
        my $self = shift;
        utf8::downgrade($self->{host});
    },
);

has port => (
    is       => 'ro',
    isa      => 'Int',
    default  => 1978,
    trigger  => sub {
        my $self = shift;
        utf8::downgrade($self->{port});
    },
);

has alias => (
    is       => 'ro',
    isa      => 'Str | Undef',
);

my $filter = any_moose('::Meta::Class')->create(
    'HTTP::Engine::Interface::POE::Filter',
    superclasses => ['POE::Filter::HTTPD'],
    methods => {
        put => sub { # omit output filter
            shift; # class name
            return @_;
        }
    },
)->name;

sub run {
    my ($self) = @_;

    # setup poe session
    POE::Component::Server::TCP->new(
        Port         => $self->port,
        Address      => $self->host,
        ClientFilter => $filter->new,
        ( $self->alias ? ( Alias => $self->alias ) : () ),
        ClientInput  => _client_input($self),
    );
}

sub _client_input {
    my $self = shift;

    sub {
        my ( $kernel, $heap, $request ) = @_[ KERNEL, HEAP, ARG0 ];

        # Filter::HTTPD sometimes generates HTTP::Response objects.
        # They indicate (and contain the response for) errors that occur
        # while parsing the client's HTTP request.  It's easiest to send
        # the responses as they are and finish up.
        if ( $request->isa('HTTP::Response') ) {
            $heap->{client}->put($request->as_string);
        } else {
            local $CLIENT = $heap->{client};
            $self->handle_request(%{ $self->_make_request($request, $heap) });
        }
        $kernel->yield('shutdown');
    }
}

sub _make_request {
    my ($self, $request, $heap) = @_;

    my ($host, $port) = $request->headers->header('Host') ?
        split(':', $request->headers->header('Host')) : ($self->host, $self->port);

    {
        headers => $request->headers,
        uri     => URI::WithBase->new(do {
            my $uri = $request->uri->clone;
            $uri->scheme('http');
            $uri->host($host);
            $uri->port($port);
            $uri->path('/') if $request->uri =~ m!^https?://!i;

            my $b = $uri->clone;
            $b->path_query('/');

            ($uri, $b);
        }),
        connection_info => {
            address    => $heap->{remote_ip},
            method     => $request->method,
            port       => $port,
            user       => undef,
            _https_info => 'OFF',
            protocol   => $request->protocol(),
            request_uri => "".$request->uri,
        },
        _connection => {
            input_handle  => do {
                my $buf = $request->content;
                open my $fh, '<', \$buf;
                $fh;
            },
            output_handle => undef,
            env           => \%ENV,
        },
    };
}

__INTERFACE__

__END__

=head1 NAME

HTTP::Engine::Interface::POE - POE interface for HTTP::Engine.

=head1 SYNOPSIS

    use POE;

    HTTP::Engine->new(
        interface => {
            module => 'POE',
            args   => {
                host => '127.0.0.1',
                port => 1984,
            },
            request_handler => sub {
                HTTP::Engine::Response->new(
                    status => 200,
                    body   => 'foo'
                )
            }
        },
    )->run;

    POE::Kernel->run();

=head1 DESCRIPTION

This is POE interface for HTTP::Engine.

=head1 ATTRIBUTES

=over 4

=item host

The bind address of TCP server.

=item port

The port number of TCP server.

=back

=head1 SEE ALSO

L<HTTP::Engine>

