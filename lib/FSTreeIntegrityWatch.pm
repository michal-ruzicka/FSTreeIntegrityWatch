
package FSTreeIntegrityWatch;

use strict;
use warnings;
use utf8;


# Public methods
use Exporter 'import';
our @EXPORT_OK = qw(
    decode_locale_if_necessary
    set_exception_verbosity
);


# External modules
use Encode;
use Encode::Locale;



# Decode string in system locale encoding to internal UTF-8 representation.
# args
#   string possibly needing conversion
# returns
#   converted string if conversion was necessary or
#   original value if no string passed or conversion was not necessary
sub decode_locale_if_necessary {

    my $s = shift @_;

    if (not ref($s) or ref($s) eq 'SCALAR') {
        return decode(locale => $s) unless (Encode::is_utf8($s));
    }

    return $s;

}

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
