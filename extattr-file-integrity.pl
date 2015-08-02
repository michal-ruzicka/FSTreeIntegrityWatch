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


# External modules
use Scalar::Util qw(blessed);
use Try::Tiny;

# FSTreeIntegrityWatch package modules
use FindBin;
use lib "$FindBin::Bin/lib/";
use FSTreeIntegrityWatch qw(decode_locale_if_necessary set_exception_verbosity);
use FSTreeIntegrityWatch::Digest qw(:standard);
use FSTreeIntegrityWatch::ExtAttr qw(:standard);



#
# Global configuration
#
my $file = "$FindBin::Bin/testdata/data/file6";
my $alg = 'SHA-1';
my $attr = $alg;
FSTreeIntegrityWatch::set_exception_verbosity('1');


#
# Main
#
try {
    my $checksum = get_file_checksum($alg, $file);
    store_file_checksum($file, $attr, $checksum);
    print "Stored '$checksum' as the extended attribute '$attr' at '$file'.\n";
} catch {
    if ( blessed $_ && $_->isa('FSTreeIntegrityWatch::Exception') ) {
        die "$_\n";
    } else {
        die $_;
    }
};


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
