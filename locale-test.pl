#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

# Set encoding translation according to system locale.
use Encode;
use Encode::Locale;
if (-t) {
    binmode(STDIN,  ":encoding(console_in)");
    binmode(STDOUT, ":encoding(console_out)");
    binmode(STDERR, ":encoding(console_out)");
} else {
    binmode(STDIN,  ":encoding(locale)");
    binmode(STDOUT, ":encoding(locale)");
    binmode(STDERR, ":encoding(locale)");
}
Encode::Locale::decode_argv(Encode::FB_CROAK);


#
# Subprograms
#

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



#
# Main
#
print "ENCODING_LOCALE:      '$Encode::Locale::ENCODING_LOCALE'\n";
print "ENCODING_LOCALE_FS:   '$Encode::Locale::ENCODING_LOCALE_FS'\n";
print "ENCODING_CONSOLE_IN:  '$Encode::Locale::ENCODING_CONSOLE_IN'\n";
print "ENCODING_CONSOLE_OUT: '$Encode::Locale::ENCODING_CONSOLE_OUT'\n";

my $msg = 'Šíleně žluťoučký kůň';
my $stdin = <STDIN>;
chomp $stdin;
my $arg = $ARGV[0];
my $smiley_from_name = "\N{WHITE SMILING FACE}";

print "MSG:    '$msg'; is_utf8 '".utf8::is_utf8($msg)."'\n";
print "MSG: /KŮŇ/ match: ".($msg =~ /KŮŇ/i ? 'ano' : 'ne')."\n";

print "STDIN:  '$stdin'; is_utf8 '".utf8::is_utf8($stdin)."'\n";
print "STDIN /KŮŇ/ match: ".($stdin =~ /KŮŇ/i ? 'ano' : 'ne')."\n";

print "ARG:    '$arg'; is_utf8 '".utf8::is_utf8($arg)."'\n";
print "ARG: /KŮŇ/ match: ".($arg =~ /KŮŇ/i ? 'ano' : 'ne')."\n";

print "SMILEY: '$smiley_from_name'; is_utf8 '".utf8::is_utf8($smiley_from_name)."'\n";

open(NONEXISTFILE, '<', "non-existing-file");
my $err = $!;
print "No decode locale error message: '$err'\n";
print "Decode locale error message:    '".decode_locale_if_necessary($err)."'\n";


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
