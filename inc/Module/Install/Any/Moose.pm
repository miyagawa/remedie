#line 1

package Module::Install::Any::Moose;
use strict;
use Module::Install::Base;

use vars qw($VERSION @ISA $ISCORE);
BEGIN {
    $VERSION = '0.00003';
    $ISCORE  = 0;
    @ISA     = qw(Module::Install::Base);
}

sub requires_any_moose {
    my $self = shift;
    my ($module, %args);

    if (@_ % 2 == 0) {
        %args = @_;
    } else {
        ($module, %args) = @_;
    }

    my $prefer = ($args{prefer} ||= 'Mouse');

    my $requires = $self->requires;
    if (! grep { $_->[0] eq 'Any::Moose' } @$requires ) {
        print "Adding Any::Moose to prerequisites...\n";
        $self->requires('Any::Moose', 0.04);
    }

    $self->_any_moose_setup($prefer, $module, %args);
    $self->_any_moose_setup(
        ($prefer eq 'Mouse' ? 'Moose' : 'Mouse'), $module, %args );
}

sub _any_moose_setup {
    my ($self, $prefix, $frag, %args) = @_;

    my $module  = $frag ? $prefix . $frag : $prefix;

    my $prefer  = $args{ prefer };
    my $version = $args{ lc $prefix };
    if ($prefer eq $prefix) {
        $self->requires($module, $version);
    } else {
        print "[Any::Moose support for $module]\n",
              "- $module ... ";

        # ripped out of ExtUtils::MakeMaker
        my $file = "$module.pm";
        $file =~ s{::}{/}g;
        eval { require $file };

        my $pr_version = $module->VERSION || 0;
        $pr_version =~ s/(\d+)\.(\d+)_(\d+)/$1.$2$3/;

        if ($@) {
            print "missing\n";
            my $y_n = ExtUtils::MakeMaker::prompt("  Add $module to the prerequisites?", 'n');
            if ($y_n =~ /^y(?:es)?$/i) {
                $self->requires($module, $version);
            } else {
                $self->recommends($module, $version);
            }
        } else {
            print "loaded ($pr_version)\n";
            $self->recommends($module, $version);
        }
    }
}

1;

__END__

#line 143
