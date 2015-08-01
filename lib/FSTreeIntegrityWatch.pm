
package FSTreeIntegrityWatch;

use strict;
use warnings;
use utf8;


# Public methods
use Exporter 'import';
our @EXPORT_OK = qw(
    set_exception_verbosity
);



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


1;


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
