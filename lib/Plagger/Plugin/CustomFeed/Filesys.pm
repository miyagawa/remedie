package Plagger::Plugin::CustomFeed::Filesys;
use strict;
use base qw( Plagger::Plugin );

use URI;
use URI::http; # for autoloading
use File::Find::Rule::Filesys::Virtual;
use Filesys::Virtual;
use URI::Escape;
use Path::Class;
use Path::Class::Unicode;
use DateTime::Format::Strptime;
use Plagger::Util;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'feed.discover' => \&handle,
    );
}

sub handle {
    my($self, $context, $args) = @_;

    if (URI->new($args->{feed}->url)->scheme eq 'file') {
        my $ident = URI->new($args->{feed}->url)->opaque;
        my($vfs, $uri) = $self->vfs_uri($ident);

        if ($vfs && $uri) {
            return sub { $self->aggregate($context, $args, $vfs, $uri) };
        }
    }

    return;
}

sub aggregate {
    my($self, $context, $args, $vfs, $uri) = @_;

    my $finder = File::Find::Rule::Filesys::Virtual->virtual($vfs);
    my @exts = @{ $self->conf->{extensions} || [] };
    $finder->name(map "*.$_", @exts) if @exts;

    my $path = udir(URI::Escape::uri_unescape($uri->path));

    my $feed = $args->{feed};
    $feed->title(($path->dir_list)[-1]); # why can't I just do $path->name?
    $feed->link($uri);

    my @files = $finder->in($path->stringify);

    my @entries;
    for my $file (@files) {
        $context->log(debug => "Found file $file");
        my $vfile = $file;
        my $vname = file($file)->ufile->basename;

        $vfile =~ s/%/%25/g;
        $vfile = file($vfile)->ufile;

        my $entry = Plagger::Entry->new;
        $entry->title($vname);
        $entry->link($vfile->uri);
        if (my $date = $vfs->modtime($file)) {
            my $parser = DateTime::Format::Strptime->new(pattern => '%Y%m%d%H%M%S');
            $entry->date($parser->parse_datetime($date));
        }
        push @entries, $entry;
    }

    my $default = DateTime->from_epoch(epoch => 0);
    # reverse chronological order if possible
    for my $entry (sort { ($b->date || $default) <=> ($a->date || $default) } @entries) {
        $feed->add_entry($entry);
    }

    $context->update->add($feed);
}

# handle file://path/to/folder and file:ssh://hostname/path
# BUT don't do anything against file://path/to/rss.xml
# TODO maybe we should use another URI scheme like filesys:?
sub vfs_uri {
    my($self, $ident) = @_;

    my($vfs, $uri);
    if ($ident =~ m!^[a-z]{2,}:!) {
        $uri = URI->new($ident);
        my $module = "Filesys::Virtual::" . uc($uri->scheme);
        eval "require $module";
        if ($@) {
            Plagger->context->error("Error loading $module: $@");
        }
        $vfs = $module->new({ host => $uri->host }); # TODO auth
    } else {
        $ident =~ s!^//!!;
        $uri = URI->new("file://$ident");

        my $dir = URI::Escape::uri_unescape($uri->path);
        unless (-d $dir) {
            ## Not a directory, probably an XML file
            return;
        }

        require Filesys::Virtual::Plain;
        $vfs = Filesys::Virtual::Plain->new;
    }

    return $vfs, $uri;
}

1;
__END__

=head1 NAME

Plagger::Plugin::CustomFeed::Filesys - File system folder as a feed

=head1 SYNOPSIS

  - module: Subscription::Config
    config:
      feed:
        - file:///path/to/videos
        - file:ssh://username:password@remote/path/videos
        - file:daap//localhost:3689/Library
  - module: CustomFeed::Filesys
    config:
      extensions:
        - mp4
        - avi

=head1 DESCRIPTION

This plugin scans local (or remote, to be implemented) filesystem and
finds files matching the extensions specified in the configuration.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
