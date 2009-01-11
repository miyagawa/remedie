use Encode::JavaScript::UCS;
use Encode;
use URI;
use Web::Scraper;

sub init {
    my $self = shift;
    $self->{handle} = '/search.html\?.*search=';
}

sub discover {
    my($self, $uri) = @_;
    return $uri;
}

sub handle {
    my($self, $plugin, $context, $args) = @_;

    my $uri = URI->new($args->{feed}->url);
    my $query = $uri->query_param('search');

    my $search_uri = URI->new("http://www.veoh.com/dwr/exec/ajaxMethodHandler.solrSearch.dwr");
    $search_uri->query_form( $self->build_params($query) ),

    my $content = $plugin->fetch_content($search_uri);
    unless ($content) {
        $context->log(error => "GET $search_uri failed");
        return;
    }

    my $html = decode("JavaScript-UCS", $content);

    if ($html =~ /s4="(.+?)";s0/){
        $html = $1;
        $html =~ s/\\\"/\"/g;
    }

    my $scraper = scraper {
        process "a.vTitle", "title[]" => 'TEXT';
        process "a.vTitle", "link[]" => '@href';
        process "img.vThumb", "thumb[]" => '@src';
        result "title", "link", "thumb";
    };

    my $data = $scraper->scrape($html);

    my @entries;
    my $count = 0;
    for my $title ( @{ $data->{title} } ) {
        if ( $data->{link}[$count] =~ m!/videos/(.+?)\?! ) {
            my $video_id  = $1;
            my $permalink = "http://www.veoh.com/videos/$video_id";
            my $thumb_url = $data->{thumb}[$count];
            push @entries,
                { title => $title, link => $permalink, thumbnail => { url => $thumb_url } };
        }
        $count++;
    }

    $plugin->update_feed($context, $args->{feed}, {
        title => sprintf('Search Results for: "%s" | Veoh Video Network', $query),
        link  => "http://www.veoh.com/search.html?type=v&search=$query",
        entry => \@entries,
    });
}

sub build_params {
    my($self, $query) = @_;

    my %param;
    my @p = qw{
callCount=1
c0-scriptName=ajaxMethodHandler
c0-methodName=solrSearch
c0-id=dummy
c0-param0=string:
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
};
    for my $p (@p) {
        $p =~ /(.+)=(.+)/;
        $param{$1} = $2;
        $param{$1} = "string:$query" if ( $1 eq "c0-param0" );
    }
    return %param;
}

