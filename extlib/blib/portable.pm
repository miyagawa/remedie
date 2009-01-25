package blib::portable;

use strict;
use 5.008_001;
our $VERSION = '0.01';

use Cwd;
use File::Spec;
use Config;

sub import {
    my $package = shift;
    my $dir = getcwd;
    if ($^O eq 'VMS') { ($dir = VMS::Filespec::unixify($dir)) =~ s-/\z--; }
    if (@_) {
        $dir = shift;
#        $dir =~ s/blib\z//;
        $dir =~ s,/+\z,,;
        $dir = File::Spec->curdir unless ($dir);
        die "$dir is not a directory\n" unless (-d $dir);
    }

    my $i = 5;
    my($blib, $blib_arch);
    while ($i--) {
        $blib = $dir;
        $blib_arch = File::Spec->catdir($blib, "arch", $Config{archname});

        if (-d $blib && -d $blib_arch) {
            unshift(@INC,$blib_arch);
            return;
        }
        $dir = File::Spec->catdir($dir, File::Spec->updir);
    }

    die "Cannot find blib even in $dir\n";
}

1;

__END__

=encoding utf-8

=for stopwords extlib

=head1 NAME

blib::portable - portable binary build libraries

=head1 SYNOPSIS

  use blib::portable;
  use blib::portable 'extlib';

=head1 DESCRIPTION

blib::portable is a pragma to push architecture specific build
directory to perl's library include path. The standard L<blib> uses
C<blib/arch> directory which is common regardless of which platform
you use.

This pragma allows you to have directory structure like:

  extlib/
    arch/
      darwin-thread-multi-2level/
        DBD/
          SQLite.pm
        auto/
          DBD/
            SQLite/
              SQLite.bs
      x86_64-linux-thread-multi/
        DBD/
          SQLite.pm
        auto/
          DBD/
            SQLite/
              SQLite.bs

and commit to the source code repository or bundle in your application
to load appropriate binary from your I<extlib>.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@cpan.orgE<gt>

Basic import code is borrowed from the original blib.pm written by perl5 porters.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<blib>, L<Config>

=cut
