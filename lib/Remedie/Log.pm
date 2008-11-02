
package Remedie::Log;
use strict;
use warnings;
use Log::Log4perl qw(:easy);
use Sub::Exporter -setup => {
    exports => [ 
        qw(TRACE DEBUG ERROR INFO WARN FATAL LOG_REQUEST),
    ],
    groups => { default => [ qw(:all) ] },
};

sub unimport {
    my $package = caller(0);
    foreach my $name qw(TRACE DEBUG ERROR INFO WARN FATAL) {
        no strict 'refs';

        if ( defined &{ $package . '::' . $name } ) {
            my $sub = \&{ $package . '::' . $name };
            next unless \&{$name} == $sub;

            delete ${ $package . '::' }{$name};
        }
    }
}

sub init {

    my $conf = '';
    if ($ENV{REMEDIE_DEBUG_LOG}) {
        $conf .= <<'        EOCONF'
            log4perl.logger = DEBUG, AppDebug, AppError, AppAccess

            # Filter to match level DEBUG
            log4perl.filter.MatchDebug  = Log::Log4perl::Filter::LevelMatch
            log4perl.filter.MatchDebug.LevelToMatch  = DEBUG
            log4perl.filter.MatchDebug.AcceptOnMatch = true

            # Debug appender
            log4perl.appender.AppDebug = Log::Log4perl::Appender::File
            log4perl.appender.AppDebug.filename = sub { $ENV{REMEDIE_DEBUG_LOG} }
            log4perl.appender.AppDebug.layout   = SimpleLayout
            log4perl.appender.AppWarn.Filter   = MatchWarn
        EOCONF
    } else {
        $conf .= <<'        EOCONF'
            log4perl.logger = INFO, AppError, AppAccess
        EOCONF
    }

    $conf .= <<'    EOCONF';
        # Filter to match level ERROR
        log4perl.filter.MatchError = Log::Log4perl::Filter::LevelMatch
        log4perl.filter.MatchError.LevelToMatch  = ERROR
        log4perl.filter.MatchError.AcceptOnMatch = true
    
        # Error appender
        log4perl.appender.AppError = Log::Log4perl::Appender::File
        log4perl.appender.AppError.filename = sub { $ENV{REMEDIE_ERROR_LOG} }
        log4perl.appender.AppError.layout   = SimpleLayout
        log4perl.appender.AppError.Filter   = MatchError

        # Filter to match level INFO
        log4perl.filter.MatchAccess = Log::Log4perl::Filter::LevelMatch
        log4perl.filter.MatchAccess.LevelToMatch  = INFO
        log4perl.filter.MatchAccess.AcceptOnMatch = true
    
        # Access appender
        log4perl.appender.AppAccess = Log::Log4perl::Appender::File
        log4perl.appender.AppAccess.filename = sub { $ENV{REMEDIE_ACCESS_LOG} }
        log4perl.appender.AppAccess.layout   = PatternLayout
        log4perl.appender.AppAccess.Filter   = MatchAccess
        log4perl.appender.AppAccess.layout.ConversionPattern = %X{request_address} - %X{request_user} [%X{request_datetime}] "%X{request_method} %X{request_path_query} %X{request_protocol}" %X{response_status} %X{response_length} "%X{request_referer}" "%X{request_user_agent}"%n
    EOCONF
    
    Log::Log4perl->init(\$conf);
}
    
sub LOG_REQUEST {
    my($req, $res) = @_;

    Log::Log4perl::MDC->put( request_address    => $req->address );
    Log::Log4perl::MDC->put( request_user       => $req->user || '-');
    Log::Log4perl::MDC->put( request_method     => $req->method);
    Log::Log4perl::MDC->put( request_path_query => $req->uri->path_query);
    Log::Log4perl::MDC->put( request_protocol   => $req->protocol);
    Log::Log4perl::MDC->put( response_status    => $res->status);
    Log::Log4perl::MDC->put( response_length    => 
        $res->body ? bytes::length($res->body) : '-');
    Log::Log4perl::MDC->put( request_referer    => $req->referer || '-');
    Log::Log4perl::MDC->put( request_user_agent => $req->user_agent || '-');
    Log::Log4perl::MDC->put( request_datetime => scalar localtime);
    
    INFO 'dummy';
}

1;