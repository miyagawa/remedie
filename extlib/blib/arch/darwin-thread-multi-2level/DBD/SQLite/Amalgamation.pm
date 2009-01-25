package DBD::SQLite::Amalgamation;
use 5.006;
use strict;
use warnings;
use version;our $VERSION = qv('3.6.1.2');
use DBD::SQLite;

1;

__END__

=head1 NAME

DBD::SQLite::Amalgamation - Single C-file based DBD::SQLite distribution

=head1 SYNOPSIS

  use DBI;
  my $dbh = DBI->connect("dbi:SQLite:dbname=dbfile","","");

=head1 DESCRIPTION

This module is nothing but a stub for an experimental way to distribute Matt
Sergeant's DBD::SQLite, using the concatenated C files (the I<amalgamation>)
as provided by the SQLite Consortium.

As of version 3.5.8, the C<FTS3> full-text search engine is now built by default.

=head1 SEE ALSO

L<DBD::SQLite>, where this module is derived from.

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

=head1 COPYRIGHT

The author disclaims copyright to this source code.  In place of
a legal notice, here is a blessing:

    May you do good and not evil.
    May you find forgiveness for yourself and forgive others.
    May you share freely, never taking more than you give.

=cut
