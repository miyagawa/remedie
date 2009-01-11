package Plagger;
use strict;
our $VERSION = '1.9.0';

use 5.8.1;
use Carp;
use Data::Dumper;
use Encode ();
use File::Copy;
use File::Basename;
use File::Find::Rule (); # don't import rule()!
use YAML;
use Storable;
use UNIVERSAL::require;

use Remedie::Log;


use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors( qw(conf update subscription plugins_path cache) );

use Plagger::Cache;
use Plagger::CacheProxy;
use Plagger::Date;
use Plagger::Entry;
use Plagger::Feed;
use Plagger::Subscription;
use Plagger::Update;
use Plagger::UserAgent; # use to define $XML::Feed::RSS::PREFERRED_PARSER

my $context;
sub context     { $context }
sub set_context { $context = $_[1] }

sub current_plugin { }

sub new {
    my($class, %opt) = @_;

    my $self = bless {
        conf  => {},
        update => Plagger::Update->new,
        subscription => Plagger::Subscription->new,
        plugins_path => {},
        plugins => [],
    }, $class;

    my $config = $opt{config};

    $self->{conf} = $config->{global};
    $self->{conf}->{log} ||= { level => 'debug' };

    if (eval { require Term::Encoding }) {
        $self->{conf}->{log}->{encoding} ||= Term::Encoding::get_encoding();
    }

    Plagger->set_context($self);

    $self->load_cache($opt{config});
    $self->load_plugins(@{ $config->{plugins} || [] });

    $self;
}

sub bootstrap {
    my $class = shift;
    my $self = $class->new(@_);
    $self->run();
    $self;
}

sub clear_session {
    my $self = shift;
    $self->{update}       = Plagger::Update->new;
    $self->{subscription} = Plagger::Subscription->new;
}

sub load_cache {
    my($self, $config) = @_;

    # use config filename as a base directory for cache
    my $base = ( basename($config) =~ /^(.*?)\.yaml$/ )[0] || 'config';
    my $dir  = $base eq 'config' ? ".plagger" : ".plagger-$base";

    # cache is auto-vivified but that's okay
    $self->{conf}->{cache}->{base} ||= File::Spec->catfile($self->home_dir, $dir);

    $self->cache( Plagger::Cache->new($self->{conf}->{cache}) );
}

sub home_dir {
    eval { require File::HomeDir };
    return $@ ? $ENV{HOME} : File::HomeDir->my_home;
}

sub load_plugins {
    my($self, @plugins) = @_;

    my $plugin_path = $self->conf->{plugin_path} || [];
       $plugin_path = [ $plugin_path ] unless ref $plugin_path;

    for my $path (@$plugin_path) {
        opendir my $dir, $path or do {
            $self->log(warn => "$path: $!");
            next;
        };
        while (my $ent = readdir $dir) {
            next if $ent =~ /^\./;
            $ent = File::Spec->catfile($path, $ent);
            if (-f $ent && $ent =~ /\.pm$/) {
                $self->add_plugin_path($ent);
            } elsif (-d $ent) {
                my $lib = File::Spec->catfile($ent, "lib");
                if (-e $lib && -d _) {
                    $self->log(debug => "Add $lib to INC path");
                    unshift @INC, $lib;
                } else {
                    my $rule = File::Find::Rule->new;
                    $rule->file;
                    $rule->name('*.pm');
                    my @modules = $rule->in($ent);
                    for my $module (@modules) {
                        $self->add_plugin_path($module);
                    }
                }
            }
        }
    }

    for my $plugin (@plugins) {
        $self->load_plugin($plugin) unless $plugin->{disable};
    }
}

sub add_plugin_path {
    my($self, $file) = @_;

    my $pkg = $self->extract_package($file)
        or die "Can't find package from $file";
    $self->plugins_path->{$pkg} = $file;
    $self->log(debug => "$file is added as a path to plugin $pkg");
}

sub extract_package {
    my($self, $file) = @_;

    open my $fh, '<', $file or die "$file: $!";
    while (<$fh>) {
        /^package (Plagger::Plugin::.*?);/ and return $1;
    }

    return;
}

sub autoload_plugin {
    my($self, $plugin) = @_;
    unless ($self->is_loaded($plugin->{module})) {
        $self->load_plugin($plugin);
    }
}

sub is_loaded {
    my($self, $stuff) = @_;

    my $sub = ref $stuff && ref $stuff eq 'Regexp'
        ? sub { $_[0] =~ $stuff }
        : sub { $_[0] eq $stuff };

    for my $plugin (@{ $self->{plugins} }) {
        my $module = ref $plugin;
           $module =~ s/^Plagger::Plugin:://;
        return 1 if $sub->($module);
    }

    return;
}

sub load_plugin {
    my($self, $config) = @_;

    my $module = delete $config->{module};
    if ($module !~ s/^\+//) {
        $module =~ s/^Plagger::Plugin:://;
        $module = "Plagger::Plugin::$module";
    }

    if ($module->isa('Plagger::Plugin')) {
        $self->log(debug => "$module is loaded elsewhere ... maybe .t script?");
    } elsif (my $path = $self->plugins_path->{$module}) {
        eval { require $path } or die $@;
    } else {
        $module->require or die $@;
    }

    $self->log(info => "plugin $module loaded.");

    my $plugin = $module->new($config);
    $plugin->cache( Plagger::CacheProxy->new($plugin, $self->cache) );
    $plugin->register($self);

    push @{$self->{plugins}}, $plugin;
}

sub register_hook {
    my($self, $plugin, @hooks) = @_;
    while (my($hook, $callback) = splice @hooks, 0, 2) {
        push @{ $self->{hooks}->{$hook} }, +{
            callback  => $callback,
            plugin    => $plugin,
        };
    }
}

sub run_hook {
    my($self, $hook, $args, $once, $callback) = @_;

    my @ret;
    for my $action (@{ $self->{hooks}->{$hook} }) {
        my $plugin = $action->{plugin};
        local *Plagger::current_plugin = sub { $plugin };
        my $ret = $action->{callback}->($plugin, $self, $args);
        $callback->($ret) if $callback;
        if ($once) {
            return $ret if defined $ret;
        } else {
            push @ret, $ret;
        }
    }

    return if $once;
    return @ret;
}

sub run_hook_once {
    my($self, $hook, $args, $callback) = @_;
    $self->run_hook($hook, $args, 1, $callback);
}

sub run {
    my $self = shift;

    $self->autoload_plugin({ module => 'Bundle::Defaults' });

    $self->run_hook('plugin.init');
    $self->run_hook('subscription.load');

    for my $feed ($self->subscription->feeds) {
        # find protocol handler from URIs like script:
        # Or discover specific feed if site RSS auto discovery is broken
        my $handler = $self->run_hook_once('feed.discover', { feed => $feed });
        if ($handler) {
            $handler->($self, { feed => $feed });
        } else {
            $self->run_hook_once('feed.fetch', { feed => $feed });
            my $ok = $self->run_hook_once('customfeed.handle', { feed => $feed });
            if (!$ok) {
                $self->log(error => $feed->url . " is not aggregated by any aggregator");
                $self->subscription->delete_feed($feed);
            }
        }
    }

    $self->run_hook('aggregator.finalize');
    $self->do_run_with_feeds;
    $self->run_hook('plugin.finalize');

    Plagger->set_context(undef);
    $self;
}

sub run_with_feeds {
    my $self = shift;
    $self->run_hook('plugin.init');
    $self->do_run_with_feeds;
    $self->run_hook('plugin.finalize');

    Plagger->set_context(undef);
    $self;
}

sub do_run_with_feeds {
    my $self = shift;

    for my $feed ($self->update->feeds) {
        for my $entry ($feed->entries) {
            $self->run_hook('update.entry.fixup', { feed => $feed, entry => $entry });
        }
        $self->run_hook('update.feed.fixup', { feed => $feed });
    }

    $self->run_hook('update.fixup');

    $self->run_hook('smartfeed.init');
    for my $feed ($self->update->feeds) {
        for my $entry ($feed->entries) {
            $self->run_hook('smartfeed.entry', { feed => $feed, entry => $entry });
        }
        $self->run_hook('smartfeed.feed', { feed => $feed });
    }
    $self->run_hook('smartfeed.finalize');

    $self->run_hook('publish.init');
    for my $feed ($self->update->feeds) {
        for my $entry ($feed->entries) {
            $self->run_hook('publish.entry.fixup', { feed => $feed, entry => $entry });
        }

        $self->run_hook('publish.feed', { feed => $feed });

        for my $entry ($feed->entries) {
            $self->run_hook('publish.entry', { feed => $feed, entry => $entry });
        }
    }

    $self->run_hook('publish.finalize');
}

sub search {
    my($self, $query) = @_;

    Plagger->set_context($self);
    $self->run_hook('plugin.init');

    my @feeds;
    $context->run_hook('searcher.search', { query => $query }, 0, sub { push @feeds, $_[0] });

    Plagger->set_context(undef);
    return @feeds;
}

sub log {
    my($self, $level, $msg, %opt) = @_;

    return unless $self->should_log($level);

    # hack to get the original caller as Plugin or Rule
    my $caller = $opt{caller};
    unless ($caller) {
        my $i = 0;
        while (my $c = caller($i++)) {
            last if $c !~ /Plugin|Rule/;
            $caller = $c;
        }
        $caller ||= caller(0);
    }

    chomp($msg);
    if ($self->conf->{log}->{encoding}) {
        $msg = Encode::decode_utf8($msg) unless utf8::is_utf8($msg);
        $msg = Encode::encode($self->conf->{log}->{encoding}, $msg);
    }

    Remedie::Log->log($level => "$caller $msg");
}

my %levels = (
    debug => 0,
    warn  => 1,
    info  => 2,
    error => 3,
);

sub should_log {
    my($self, $level) = @_;
    $levels{$level} >= $levels{$self->conf->{log}->{level}};
}

sub error {
    my($self, $msg) = @_;
    my($caller, $filename, $line) = caller(0);
    chomp($msg);
    die "$caller [fatal] $msg at line $line\n";
}

sub dumper {
    my($self, $stuff) = @_;
    local $Data::Dumper::Indent = 1;
    $self->log(debug => Dumper($stuff));
}

1;
__END__

=head1 NAME

Plagger - Pluggable RSS/Atom Aggregator

=head1 SYNOPSIS

  % plagger -c config.yaml

=head1 DESCRIPTION

Plagger is a pluggable RSS/Atom feed aggregator and remixer platform.

Everything is implemented as a small plugin just like qpsmtpd, blosxom
and perlbal. All you have to do is write a flow of aggregation,
filters, syndication, publishing and notification plugins in config
YAML file.

See L<http://plagger.org/> for cookbook examples, quickstart document,
development community (Mailing List and IRC), subversion repository
and bug tracking.

=head1 BUGS / DEVELOPMENT

If you find any bug, or you have an idea of nice plugin and want help
on it, drop us a line to our mailing list
L<http://groups.google.com/group/plagger-dev> or stop by the IRC
channel C<#plagger> at irc.freenode.net.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

See I<AUTHORS> file for the name of all the contributors.

=head1 LICENSE

Except where otherwise noted, Plagger is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://plagger.org/>

=cut
