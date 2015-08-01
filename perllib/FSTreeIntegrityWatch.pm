
package FSTreeIntegrityWatch;

use strict;
use warnings;
use utf8;

# Public methods
use Exporter 'import';
our @EXPORT_OK = qw(
    get_file_checksum
    set_stack_trace_prints
);
our %EXPORT_TAGS = (
    all      => [ @EXPORT_OK ],
    standard => [ qw(
        get_file_checksum
    ) ],
);

# Error prints
use Carp qw(carp cluck croak confess);


# External modules
use Digest::SHA;
use File::ExtAttr ':all';



# Enable/disable stack trace for carp/cluck error prints
sub set_stack_trace_prints {

    my $value = shift @_;

    if ($value =~ /^[10]$/) {
        $Carp::Verbose = $value;
    } else {
        carp "Invalid parameter, use '0' or '1'";
    }

}

# Compute checksum on given file using selected algorithm.
# Returns
# the checksum as string
# or undef in case of an error.
sub get_file_checksum {

    my ($alg, $filename) = @_;
    my $rv = undef;

    if (not defined($filename)) {

        carp "No filename specified";

    } elsif (-e $filename and -f $filename and -r $filename) {

        if (not defined($alg)) {

            carp "No digest algorithm specified";

        } elsif ($alg !~ /^SHA-?(1|224|256|384|512)$/i) {

            carp "'$alg' is not valid digest algorithm";

        } else {

            my $checksumer = Digest::SHA->new("$alg", 'b');
            $rv = $checksumer->addfile($filename)->hexdigest;

        }

    } else {

        carp "'$filename' is not readable file";

    }

    return $rv;

}


1;


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
