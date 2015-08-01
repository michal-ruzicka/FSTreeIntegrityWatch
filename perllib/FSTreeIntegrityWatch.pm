
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


# Package modules
use FSTreeIntegrityWatch::Exception;

# External modules
use Digest::SHA;
use File::ExtAttr ':all';



# Enable/disable stack trace for carp/cluck error prints
# args
#   1 or 0 to enable/disable stack trace prints
# throws
#   FSTreeIntegrityWatch::Exception::Configuration in case invalid argument
sub set_stack_trace_prints {

    my $value = shift @_;

    if ($value =~ /^[10]$/) {
        $Carp::Verbose = $value;
    } else {
        my $err = "Invalid parameter, use '0' or '1'";
        carp "$err";
        FSTreeIntegrityWatch::Exception::Configuration->throw($err);
    }

}

# Compute checksum on given file using selected algorithm.
# args
#   algorithm to compute the checksum with
#   path of file to compute the checksum of
# returns
#   the checksum as string
#   or undef in case of an error.
# throws
#   FSTreeIntegrityWatch::Exception::Digest in case of any error
sub get_file_checksum {

    my ($alg, $filename) = @_;
    my $rv = undef;

    # Check parameters
    my $err = undef;
    if (not defined($filename)) {
        $err = "No filename specified";
    } elsif (-e $filename and -f $filename and -r $filename) {
        if (not defined($alg)) {
            $err = "No digest algorithm specified";
        } elsif ($alg !~ /^SHA-?(1|224|256|384|512)$/i) {
            $err = "'$alg' is not a valid digest algorithm";
        }
    } else {
        $err = "'$filename' is not readable file";
    }

    if (defined($err)) {
        carp "$err";
        FSTreeIntegrityWatch::Exception::Digest->throw($err);
    } else {
        my $checksumer = Digest::SHA->new("$alg", 'b');
        $rv = $checksumer->addfile($filename)->hexdigest;
    }

    return $rv;

}


1;


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
