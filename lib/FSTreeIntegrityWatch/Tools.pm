
package FSTreeIntegrityWatch::Tools;

use strict;
use warnings;
use utf8;


# External modules
use Encode;
use Encode::Locale;


# Public methods
use Exporter 'import';
our @EXPORT_OK = qw(
    decode_locale_if_necessary
);
our %EXPORT_TAGS = (
    all      => [ @EXPORT_OK ],
    standard => [ qw(
        decode_locale_if_necessary
    ) ],
);



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


1;


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
