use Encode::JavaScript::UCS;
use Encode;
use URI;
use Web::Scraper;

sub init {
    my $self = shift;
    $self->{handle} = '/search.html\?.*search=';
}

sub handle {
    my($self, $plugin, $context, $args) = @_;

    my $uri = URI->new($args->{feed}->url);
    my $query = $uri->query_param('search');

    my $search_uri = URI->new("http://www.veoh.com/dwr/exec/ajaxMethodHandler.solrSearch.dwr");
    $search_uri->query_form( $self->build_params($query) );

    my $res = Plagger::UserAgent->new->fetch($search_uri);
    unless ($res->is_success) {
        $context->log(error => "GET $search_uri failed: " . $res->http_response->status_line);
        return;
    }

    my $html = decode("JavaScript-UCS", $res->content);

    if ($html =~ /s4="(.+?)";s0/){
        $html = $1;
        $html =~ s/\\\"/\"/g;
    }

    my $scraper = scraper {
        process ".vList_vFull>li", "videos[]" => scraper {
            process "a.vTitle", "title" => 'TEXT';
            process "a.vTitle", "link" => [ '@href',
                                            sub { m!/videos/(.+?)\?! and return "http://www.veoh.com/videos/$1" } ];
            process "img.vThumb", "thumbnail" =>  [ '@src', sub { +{ url => $_ } } ];
        };
    };

    my $data = $scraper->scrape($html);

    return {
        title => sprintf('Search Results for: "%s" | Veoh Video Network', $query),
        link  => "http://www.veoh.com/search.html?type=v&search=$query",
        entry => $data->{videos},
    };
}

sub build_params {
    my($self, $query) = @_;

    (my $params = <<PARAM) =~ s/__QUERY__/$query/;
callCount=1
c0-scriptName=ajaxMethodHandler
c0-methodName=solrSearch
c0-id=dummy
c0-param0=string:__QUERY__
c0-param1=string:v
c0-param2=string:searchResultsHolder
c0-param3=string:%2FWEB-INF%2Fpages%2Fsnippets%2FajaxSearch.jsp
c0-param4=number:20
c0-param5=boolean:true
c0-param6=string:mr
c0-param7=string:a
c0-param8=number:0
c0-param9=null:null
c0-param10=string:
c0-param11=string:
c0-param12=string:
c0-param13=number:0
c0-param14=string:thumb
c0-param15=string:dummy
c0-param16=boolean:false
c0-param17=number:-1
c0-param18=number:-1
xml=true
PARAM

    return split /[\n=]/, $params;
}
