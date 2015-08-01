
package FSTreeIntegrityWatch::Digest;

use strict;
use warnings;
use utf8;


# Public methods
use Exporter 'import';
our @EXPORT_OK = qw(
    get_file_checksum
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
use Digest;
use Try::Tiny;



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
        $err = "No digest algorithm specified." if (not defined($alg));
    } else {
        $err = "'$filename' is not a readable file.";
    }

    digest_error($err) if (defined($err));
    try {
        my $checksumer = Digest->new("$alg", 'b');
        $rv = $checksumer->addfile($filename)->hexdigest;
    } catch {
        digest_error("Digest computation using '$alg' algorithm failed.\n".$_);
    };

    return $rv;

}


1;


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
