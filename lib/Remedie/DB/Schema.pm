package Remedie::DB::Schema;
use strict;
use Moose;
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
  props      TEXT
);
--
CREATE UNIQUE INDEX item_ident ON item (channel_id, ident);
SQL
}

sub upgrade {
    my $class = shift;

    my $db  = Remedie::DB->new;
    my $dbh = $db->dbh;

    my $sth = $dbh->prepare('SELECT version FROM remedie_schema');
    my $version;
    eval {
        $sth->execute;
        $version = $sth->fetchrow_arrayref->[0];
    };

    ## TODO we want something like SQLite::Diff here
}

1;
