package Remedie::Log;
use strict;
use warnings;
use Log::Dispatch;
use Log::Dispatch::File;

my($logger, $access_logger);

my %alias = (warn => 'warning');

sub init {
    unless ($logger) {
        $logger = Log::Dispatch->new;
        $logger->add( Log::Dispatch::File->new(
            name => 'error_log',
            min_level => $ENV{REMEDIE_DEBUG} ? 'debug' : 'warning',
            filename  => $ENV{REMEDIE_ERROR_LOG} . "",
            mode => 'append',
        ));

        $access_logger = Log::Dispatch->new;
        $access_logger->add( Log::Dispatch::File->new(
            name => 'access_log',
            min_level => 'info',
            filename  => $ENV{REMEDIE_ACCESS_LOG} . "",
            mode => 'append',
        ));
    }

    $logger;
}

sub log {
    my($class, $level, @msg) = @_;

    unless ($logger) {
        Carp::croak("Remedie::Log::init() should be called.");
    }

    my $msg = join(" ", @msg);
    chomp $msg;
    $logger->log( level => $alias{$level} || $level, message => "$msg\n" );
}

sub log_request {
    my($class, $req, $res) = @_;

    $access_logger->log(
        level => 'info',
        message => sprintf qq(%s - %s [%s] "%s %s %s" %s %s "%s" "%s"\n),
            $req->address, ($req->user || '-'), scalar localtime, $req->method,
            $req->uri->path_query, $req->protocol, $res->status, ($res->body ? bytes::length($res->body) : "-"),
            ($req->referer || '-'), ($req->user_agent || '-'),
    );
}

for my $level ( qw(debug info notice warn warning error critical alert emergency) ) {
    no strict 'refs';
    *$level = sub {
        my $class = shift;
        $class->log( $level => @_ );
    };
}

1;
