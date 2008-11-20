package Remedie::Server::RPC::Extension;
use Moose;

BEGIN { extends 'Remedie::Server::RPC' };

__PACKAGE__->meta->make_immutable;

no Moose;

sub list {
    my($self, $req, $res) = @_;

	my $root = $self->conf->{root};
	my @extensions = map {
	    $_ =~ s!.*(remedie\.ext\..*?\.js)$!$1!;
        $_;
    } glob("$root/static/js/remedie.ext.*.js");
	return { extensions => \@extensions };
}


1;
