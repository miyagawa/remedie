package Remedie::Download;
use Any::Moose;
use UNIVERSAL::require;

sub new {
    my($class, $impl, @args) = @_;

    my $module = "Remedie::Download::$impl";
    $module->require or die $@;

    return $module->new(@args);
}

1;
