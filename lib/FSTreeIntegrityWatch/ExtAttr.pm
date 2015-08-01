
package FSTreeIntegrityWatch::ExtAttr;

use strict;
use warnings;
use utf8;


# Public methods
use Exporter 'import';
our @EXPORT_OK = qw(
    store_file_checksum
);
our %EXPORT_TAGS = (
    all      => [ @EXPORT_OK ],
    standard => [ qw(
        store_file_checksum
    ) ],
);


# Package modules
use FSTreeIntegrityWatch::Exception qw(:all);

# External modules
use File::ExtAttr ':all';
use Try::Tiny;



# Store checksum to given file's extended attribute.
# args
#   path of file to store the checksum to
#   name of the extended attribute the checksum to store to
#   checksum to store
# returns
#   1 on success
#   undef otherwise.
# throws
#   FSTreeIntegrityWatch::Exception::ExtAttr in case of any error
sub store_file_checksum {

    my ($filename, $attrname, $checksum) = @_;
    my $rv = undef;

    # Check parameters
    my $err = undef;
    if (not defined($filename)) {
        $err = "No filename specified.";
    } elsif (-e $filename and -f $filename and -w $filename) {
        $err = "No valid extended attribute name provided." if (not defined($attrname) or $attrname =~ /^\s*$/);
        $err = "No valid checksum provided." if (not defined($checksum) or $checksum =~ /^\s*$/);
    } else {
        $err = "'$filename' is not a writable file.";
    }

    extattr_error($err) if (defined($err));
    try {
        setfattr($filename, $attrname, $checksum);
        $rv = 1;
    } catch {
        extattr_error("Faild to store checksum '$checksum' to file '$filename' in extended attribute '$attrname':".$!);
    };

    return $rv;

}


1;


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
