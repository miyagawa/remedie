package Plagger::Plugin::Bundle::Remedie;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;

    my @want_mime = qw( audio video bittorrent );
    my @want_ext  = qw( avi mp4 divx mp3 m4a m4v mkv flv wmv asx torrent );

    $context->load_plugin({
        module => 'CustomFeed::FindLinks',
        config => {
            follow_xpath => "//a[" . join(" or ", map "contains(\@href, '.$_')", @want_ext) . "]",
            follow_link  => "//a[" . join(" or ", map "contains(\@type, '$_')", @want_mime) . "]",
        },
    });

#    $context->autoload_plugin({ module => 'Filter::TruePermalink' });
    $context->autoload_plugin({ module => 'Namespace::iTunesDTD' });
    $context->autoload_plugin({ module => 'Filter::FindEnclosures' });
    $context->autoload_plugin({ module => 'Filter::ExtractThumbnail' });
    $context->autoload_plugin({ module => 'Filter::HTMLScrubber',
                                config => { default_deny => 1,
                                            allow => [ qw( p br div ) ],
                                            rules => { img => 0 } } });
    $context->autoload_plugin({ module => 'Filter::GuessImageSize' });
#    $context->autoload_plugin({ module => 'Filter::ImageInfo' });
}

1;
