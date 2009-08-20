# http://www.animate.tv/radio/szbh/
use URI::QueryParam;
sub init {
    my $self = shift;
    $self->{handle} = "/radio/";
}

sub build_scraper {
    scraper {
        my $top;
        process '#pagetop a', _top => [ '@href', sub { $top = $_ } ];
        process 'table.playlist', 'entries[]' => scraper {
            process '//th[@colspan="3"]', title => 'TEXT';
            process 'td.radio_td', body => 'TEXT';
            process '//th[@align="right"]', date => ['TEXT',
                    sub { s!(\d{4})/(\d\d?)/(\d\d?)\s.*$!$1-$2-$3! } ];
            # play.php checks Referer to generate asx URLs :/
            process '.play_btn a', link => '@href',
                enclosure => [ '@href', sub {
                                   my $uri = $top->clone;
                                   $uri->fragment($_->query_param('id'));
                                   return { url => $uri, type => 'text/html' };
                               } ];
        };
        process 'title', title => 'TEXT';
        process '.box_img img', thumbnail => '@src';
        process '.html_box1', description => 'TEXT';
    };
}
