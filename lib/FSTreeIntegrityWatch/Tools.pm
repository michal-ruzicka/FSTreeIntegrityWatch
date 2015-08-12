
package FSTreeIntegrityWatch::Tools;

use strict;
use warnings;
use utf8;


# Package modules
use FSTreeIntegrityWatch::Exception qw(:all);

# External modules
use DateTime;
use Encode::Locale;
use Encode;


# Public methods
use Exporter 'import';
our @EXPORT_OK = qw(
    decode_locale_if_necessary
    get_iso8601_formated_datetime
);
our %EXPORT_TAGS = (
    all      => [ @EXPORT_OK ],
    standard => [ qw(
        decode_locale_if_necessary
        get_iso8601_formated_datetime
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

# Get timestamp as ISO 8601 formated string in the local time zone.
# args
#   if no argument is given current time timestamp is returned
#   if ISO 8601 formatted timestamp string is given the corresponding time
#      timestamp in the local time zone is returen
# returns
#   timestamp as ISO 8601 formated string
# throws
#   FSTreeIntegrityWatch::Exception::Param::Format in case of an argument given
#     not in a valid ISO 8601 format
sub get_iso8601_formated_datetime {

    my $iso8601_ts = shift @_;

    my $ts_output_format = '%Y-%m-%dT%H:%M:%S%z';
    my $ts_output_timezone = 'local';

    if (defined($iso8601_ts)) {
        if ($iso8601_ts =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(Z|[+-](\d{4}|\d{6}))$/) {
            my $dt = DateTime->new(
                year       => "$1",
                month      => "$2",
                day        => "$3",
                hour       => "$4",
                minute     => "$5",
                second     => "$6",
                time_zone  => "$7",
            );
            return $dt->set_time_zone($ts_output_timezone)->strftime($ts_output_format);
        } else {
            param_format_error("Timestamp '$iso8601_ts' is not in a valid ISO 8601 format.");
        }
    } else {
        return DateTime->now(time_zone => "$ts_output_timezone")->strftime($ts_output_format);
    }

}


1;


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
