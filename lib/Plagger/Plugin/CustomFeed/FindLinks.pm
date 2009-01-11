package Plagger::Plugin::CustomFeed::FindLinks;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use List::Util qw(first);
use HTML::ResolveLink;
use HTML::Selector::XPath;
use HTML::TreeBuilder::XPath;
use Plagger::Util qw( decode_content extract_title );
use URI::filename;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'customfeed.handle' => \&handle,
    );
}

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->load_assets('yaml', sub { $self->load_plugin_yaml(@_) });
}

sub asset_key { 'find_links' }

sub load_plugin_yaml {
    my($self, $file, $domain) = @_;

    Plagger->context->log(debug => "Load YAML $file");
    my $data = YAML::LoadFile($file);

    return Plagger::Plugin::Filter::FindLinks::YAML->new($data, $domain);
}

sub handle {
    my($self, $context, $args) = @_;

    my $handler = $self->asset_for($args->{feed}->url);
    if ($handler) {
        $args->{match}    = $handler->follow_link;
        $args->{xpath}    = $handler->follow_xpath;
        $args->{selector} = $handler->follow_selector;
    } else {
        $args->{match}    = $args->{feed}->meta->{follow_link}     || $self->conf->{follow_link};
        $args->{xpath}    = $args->{feed}->meta->{follow_xpath}    || $self->conf->{follow_xpath};
        $args->{selector} = $args->{feed}->meta->{follow_selector} || $self->conf->{follow_selector};
    }

    if ($args->{selector}) {
        $args->{xpath} = HTML::Selector::XPath::selector_to_xpath($args->{selector});
    }

    if ($args->{match} || $args->{xpath}) {
        return $self->aggregate($context, $args);
    }

    return;
}

sub aggregate {
    my($self, $context, $args) = @_;

    my $url = $args->{feed}->url;
    my $res = $args->{feed}->source;

    if (!$res or $res->http_response->is_error) {
        $context->log(error => "GET $url failed");
        return;
    }

    my $content = decode_content($res);

    my $feed = Plagger::Feed->new;
    $feed->title($args->{feed}->title || extract_title($content));
    $feed->link($url);

    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse($content);
    $tree->eof;

    my %found;
    my $found;
    for my $child ( $tree->findnodes($args->{xpath} || '//a') ) {
        my $href  = $child->attr('href') or next;

        if (my $re = $args->{match}) {
            $href =~ /$re/ or next;
        }

        my $item_url = URI->new_abs($href, $url);
        my $entry = $found{$item_url} || do {
            my $e = Plagger::Entry->new;
            $feed->add_entry($e);
            $e;
        };

        if (my($img) = $child->look_down(_tag => 'img')) {
            $entry->icon({
                url    => URI->new_abs($img->attr('src'), $url),
                width  => $img->attr('width'),
                height => $img->attr('height'),
            });
        }

        if (my $title = $child->attr('title') || $child->as_text) {
            $entry->title($title);
        } else {
            $entry->title($item_url->filename)
                unless $entry->title;
        }

        $entry->link($item_url);

        $context->log(debug => "Add $href (" . $entry->title . ")");
        $found++;
        $found{$item_url} = $entry;
    }

    if ($found) {
        $context->update->add($feed);
        return 1;
    } else {
        return;
    }
}


package Plagger::Plugin::Filter::FindLinks::YAML;
use Encode;
use List::Util qw(first);

sub new {
    my($class, $data, $domain) = @_;

    # add ^ if handle method starts with http://
    for my $key ( qw(handle handle_force) ) {
        next unless defined $data->{$key};
        $data->{$key} = "^$data->{$key}" if $data->{$key} =~ m!^https?://!;
    }

    bless {%$data, domain => $domain }, $class;
}

sub domain {
    $_[0]->{domain};
}

sub follow_link {
    $_[0]->{follow_link};
}

sub follow_xpath {
    $_[0]->{follow_xpath};
}

sub follow_selector {
    $_[0]->{follow_selector};
}


package Plagger::Plugin::CustomFeed::FindLinks;

1;

__END__

=head1 NAME

Plagger::Plugin::CustomFeed::FindLinks - Simple way to create title and link only custom feeds

=head1 SYNOPSIS

  - module: Subscription::Config
    config:
      feed:
        - url: http://sportsnavi.yahoo.co.jp/index.html
          meta:
            follow_link: /headlines/
        - url: http://d.hatena.ne.jp/antipop/20050628/1119966355
          meta:
            follow_xpath: //ul[@class="xoxo" or @class="subscriptionlist"]//a

  - module: CustomFeed::FindLinks

=head1 DESCRIPTION


=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut



1;
