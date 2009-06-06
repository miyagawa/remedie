package Plagger::Plugin::CustomFeed::Spotlight;
use strict;
use base qw( Plagger::Plugin );

use URI;
use File::Spotlight;
use URI::Escape;
use Path::Class;
use Path::Class::Unicode;
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
        my $path = URI->new($args->{feed}->url)->path;
        if ($path =~ /\.savedSearch$/) {
            return sub { $self->aggregate($context, $args, file(URI::Escape::uri_unescape($path)) ) };
        }
    }

    return;
}

sub aggregate {
    my($self, $context, $args, $path) = @_;

    my $folder = File::Spotlight->new($path->stringify);

    my $name = $path->basename;
    $name =~ s/\.savedSearch$//;

    my $feed = $args->{feed};
    $feed->title($name);
    $feed->link($args->{feed}->url);

    my @files = $folder->list();

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
        if (my $mtime = (stat($file))[9]) {
            $entry->date(Plagger::Date->from_epoch($mtime));
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

1;
__END__

=head1 NAME

Plagger::Plugin::CustomFeed::Spotlight - Mac OS X Smart Folder as a feed

=head1 SYNOPSIS

  - module: Subscription::Config
    config:
      feed:
        - file:///Users/miyagawa/Library/Saved Searches/Smart Folder.savedSearch
  - module: CustomFeed::Spotlight

=head1 DESCRIPTION

This plugin lists files from OS X Smart Folders to handle files as a
source. You are recommended to set I<Kind> equal I<Movies> to only
match with movie files matching with your search criteria.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger> L<File::Spotlight>

=cut
