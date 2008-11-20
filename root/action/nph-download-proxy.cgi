#!/usr/bin/perl
use strict;
use CGI::Simple;
use WWW::NicoVideo::Download;

# Access as nph-download-proxy.cgi/sm9
my $email    = 'YOUR-EMAIL@example.com';
my $password = 'YOUR-PASSWORD';

my $query    = CGI::Simple->new;
my $video_id = ($query->path_info =~ m!^/(\w+)!)[0];

my $client = WWW::NicoVideo::Download->new( email => $email, password => $password );
my $url = $client->prepare_download($video_id);

my $req = HTTP::Request->new( GET => $url );
if ($ENV{HTTP_RANGE}) {
    $req->header( Range => $ENV{HTTP_RANGE} );
}
my $res = $client->user_agent->request( $req, make_callback($video_id) );

if ($res->is_error) {
    print $res->as_string;
}

sub make_callback {
    my $video_id = shift;

    my $header_printed;
    return sub {
        my($data, $res, $proto) = @_;

        unless ($header_printed) {
            print "HTTP/1.0 " . $res->status_line . "\n";

            if (my $ctd = $res->header("Content-Disposition")) {
                $ctd =~ s/smile\./$video_id./;
                $res->header("Content-Disposition" => $ctd);
            }

            print $res->headers->as_string;
            $header_printed++;
        }

        print $data;
    };
}
