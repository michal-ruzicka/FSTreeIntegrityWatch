
package FSTreeIntegrityWatch;

use strict;
use warnings;
use utf8;


# Public methods
use Exporter 'import';
our @EXPORT_OK = qw(
    get_file_checksum
    set_exception_verbosity
);
our %EXPORT_TAGS = (
    all      => [ @EXPORT_OK ],
    standard => [ qw(
        get_file_checksum
    ) ],
);


# Package modules
use FSTreeIntegrityWatch::Exception qw(:all);

# External modules
use Digest::SHA;
use File::ExtAttr ':all';



# Enable/disable stack trace as part of the standard exception error message.
# args
#   1 or 0 (default) to enable/disable stack trace in exception error messages
# throws
#   FSTreeIntegrityWatch::Exception::Configuration in case of an invalid
#                                                  argument
sub set_exception_verbosity {

    my $value = shift @_;

    if ($value =~ /^[10]$/) {
        $FSTreeIntegrityWatch::Exception::exception_verbosity = $value;
    } else {
        config_error("Invalid parameter, use '0' or '1'.");
    }

}

# Compute checksum on given file using selected algorithm.
# args
#   algorithm to compute the checksum with
#   path of file to compute the checksum of
# returns
#   the checksum as string or
#   undef in case of an error.
# throws
#   FSTreeIntegrityWatch::Exception::Digest in case of any error
sub get_file_checksum {

    my ($alg, $filename) = @_;
    my $rv = undef;

    # Check parameters
    my $err = undef;
    if (not defined($filename)) {
        $err = "No filename specified.";
    } elsif (-e $filename and -f $filename and -r $filename) {
        if (not defined($alg)) {
            $err = "No digest algorithm specified.";
        } elsif ($alg !~ /^SHA-?(1|224|256|384|512)$/i) {
            $err = "'$alg' is not a valid digest algorithm.";
        }
    } else {
        $err = "'$filename' is not a readable file.";
    }

    if (defined($err)) {
        digest_error($err);
    } else {
        my $checksumer = Digest::SHA->new("$alg", 'b');
        $rv = $checksumer->addfile($filename)->hexdigest;
    }

    return $rv;

}


1;


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
