package Remedie::DB::Schema;
use Moose;

__PACKAGE__->meta->make_immutable;

no Moose;

use Remedie::DB;

sub install {
    my $class = shift;

    my $db  = Remedie::DB->new;
    my $dbh = $db->dbh;
    $dbh->do($_) for split /--/, <<'SQL';
CREATE TABLE channel (
  id      INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  type    INTEGER NOT NULL,
  parent  INTEGER NOT NULL,
  ident   TEXT NOT NULL,
  name    TEXT NOT NULL,
  props   TEXT
);
--
CREATE UNIQUE INDEX channel_ident ON channel (ident);
--
CREATE TABLE item (
  id         INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  channel_id INTEGER NOT NULL,
  type       INTEGER NOT NULL,
  ident      TEXT NOT NULL,
  name       TEXT NOT NULL,
  status     INTEGER NOT NULL,
  props      TEXT
);
--
CREATE INDEX item_status ON item (status)
--
CREATE UNIQUE INDEX item_ident ON item (channel_id, ident);
SQL
}

sub upgrade {
    my $class = shift;

    my $db  = Remedie::DB->new;
    my $dbh = $db->dbh;
    my $sth = $dbh->prepare("SELECT name FROM sqlite_master WHERE type IN (?)");
    $sth->execute('table');

    my %tables;
    while (my $row = $sth->fetchrow_arrayref) {
        $tables{$row->[0]} = 1;
    }

    unless ($tables{channel}) {
        $class->install();
    }

    return 1;
}

1;
