package Plagger::Plugin::Bundle::Remedie;
use strict;
use base qw( Plagger::Plugin );

use Plagger::Util;

sub register {
    my($self, $context) = @_;

    # TODO share this with Plagger::Util::mime_is_enclosure
    my @want_mime = qw( audio video bittorrent );
    my @want_ext  = qw( avi mp4 divx mp3 m4a m4v mov mkv flv wmv wma swf asx wvx torrent );

    $context->load_plugin({
        module => 'CustomFeed::Filesys',
        config => {
            extensions => \@want_ext,
        },
    });

    $context->load_plugin({ module => 'CustomFeed::Scraper' });

    $context->load_plugin({
        module => 'CustomFeed::FindLinks',
        config => {
            follow_xpath => "//a[contains(\@rel, 'enclosure') or " .
                                 join(" or ", map "contains(\@href, '.$_')", @want_ext) . " or " .
                                 join(" or ", map "contains(\@type, '$_')", @want_mime) . "]",
        },
    });

    $context->load_plugin({ module => 'Discovery::Sites' });
    $context->load_plugin({ module => 'CustomFeed::Script' });

    my $thumb_dir = $self->conf->{user_data}->path_to_dir("thumb")->udir;

 #    $context->autoload_plugin({ module => 'Filter::TruePermalink' });
    $context->autoload_plugin({ module => 'Filter::FeedBurnerPermalink' });
    $context->autoload_plugin({ module => 'Namespace::iTunesDTD' });
    $context->autoload_plugin({ module => 'Namespace::ApplePhotocast' });
    $context->autoload_plugin({ module => 'Namespace::HatenaFotolife' });
    $context->autoload_plugin({ module => 'Filter::EnclosureMetadata' });
    $context->autoload_plugin({ module => 'Filter::FindEnclosures' });
    $context->autoload_plugin({ module => 'Filter::MediaFilename' });
    $context->autoload_plugin({ module => 'Filter::EnclosureThumbnail',
                                config => { thumb_dir => $thumb_dir } });
    $context->autoload_plugin({ module => 'Filter::ExtractThumbnail',
                                config => { min_size => 5_000 } });
    $context->autoload_plugin({ module => 'Filter::HTMLScrubber',
                                config => { default_deny => 1,
                                            allow => [ qw( p br div ) ],
                                            rules => { img => 0 } } });
    $context->autoload_plugin({ module => 'Filter::GuessImageSize' });
#    $context->autoload_plugin({ module => 'Filter::ImageInfo' });
    $context->autoload_plugin({ module => 'Filter::RewriteThumbnailURL',
                                config => {
                                    rewrite => [
                                        { local => $thumb_dir->uri,
                                          url   => "/thumb" } # relative URL
                                    ],
                                } });
}

1;
