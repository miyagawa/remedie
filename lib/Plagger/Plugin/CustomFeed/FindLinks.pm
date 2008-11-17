package Plagger::Plugin::CustomFeed::FindLinks;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use List::Util qw(first);
use HTML::TokeParser;
use HTML::ResolveLink;
use HTML::TreeBuilder::XPath;
use Plagger::UserAgent;
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
    $self->load_plugins();

    $self->{ua} = Plagger::UserAgent->new;
}

sub load_plugins {
    my $self = shift;
    my $context = Plagger->context;

    $self->load_assets('*.yaml', sub { $self->load_plugin_yaml(@_) });
}

sub load_plugin_yaml {
    my($self, $file, $base) = @_;

    Plagger->context->log(debug => "Load YAML $file");
    my @data = YAML::LoadFile($file);

    push @{ $self->{plugins} },
        map { Plagger::Plugin::Filter::FindLinks::YAML->new($_, $base) } @data;
}

sub handle {
    my($self, $context, $args) = @_;

    my $handler = first { $_->custom_feed_handle($args) } @{ $self->{plugins} };
    if ($handler) {
        $args->{match} = $handler->custom_feed_follow_link;
        $args->{xpath} = $handler->custom_feed_follow_xpath;
    } else {
        $args->{match} = $args->{feed}->meta->{follow_link}  || $self->conf->{follow_link};
        $args->{xpath} = $args->{feed}->meta->{follow_xpath} || $self->conf->{follow_xpath};
    }

    if ($args->{match} || $args->{xpath}) {
        return $self->aggregate($context, $args);
    }

    return;
}

sub aggregate {
    my($self, $context, $args) = @_;

    my $url = $args->{feed}->url;
    $context->log(info => "GET $url");

    my $agent = Plagger::UserAgent->new;
    my $res = $agent->fetch($url, $self);

    if ($res->http_response->is_error) {
        $context->log(error => "GET $url failed: " . $res->status);
        return;
    }

    my $content = decode_content($res);

    my $feed = Plagger::Feed->new;
    $feed->title($args->{feed}->title || extract_title($content));
    $feed->link($url);

    my $found;
    my %found;
    if( my $re = $args->{match} ) {
        my $resolver = HTML::ResolveLink->new(base => $url);
        $content = $resolver->resolve($content);

        my %seen;
        my $parser = HTML::TokeParser->new(\$content);
        while (my $token = $parser->get_tag('a')) {
            ($token->[1]->{href} || '') =~ /$re/ or next;

            my $item_url = URI->new_abs($token->[1]->{href}, $url);
            next if $seen{$item_url->as_string}++;

            my $text = $parser->get_trimmed_text('/a');
            if (!$text || $text eq '[IMG]') {
                $text = $item_url->filename;
            }

            my $entry = Plagger::Entry->new;
            $entry->title($text);
            $entry->link($item_url);
            $feed->add_entry($entry);

            $context->log(debug => "Add $token->[1]->{href} ($text)");
            $found++;
            $found{$item_url}++;
        }
    }

    if (my $xpath = $args->{xpath}) {
        my $tree = HTML::TreeBuilder::XPath->new;
        $tree->parse($content);
        $tree->eof;

        for my $child ( $tree->findnodes($xpath || '//a') ) {
            my $href  = $child->attr('href') or next;
            my $title = $child->attr('title') || $child->as_text;

            my $item_url = URI->new_abs($href, $url);
            next if $found{$item_url}++;

            my $entry = Plagger::Entry->new;
            $entry->title($title);
            $entry->link($item_url);
            $feed->add_entry($entry);

            $context->log(debug => "Add $href ($title)");
            $found++;
        }
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
    my($class, $data, $base) = @_;

    # add ^ if handle method starts with http://
    for my $key ( qw(custom_feed_handle handle handle_force) ) {
        next unless defined $data->{$key};
        $data->{$key} = "^$data->{$key}" if $data->{$key} =~ m!^https?://!;
    }

    bless {%$data, base => $base }, $class;
}

sub site_name {
    my $self = shift;
    $self->{base};
}

sub custom_feed_handle {
    my($self, $args) = @_;
    $self->{custom_feed_handle} ?
        $args->{feed}->url =~ /$self->{custom_feed_handle}/ : 0;
}

sub custom_feed_follow_link {
    $_[0]->{custom_feed_follow_link};
}

sub custom_feed_follow_xpath {
    $_[0]->{custom_feed_follow_xpath};
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
