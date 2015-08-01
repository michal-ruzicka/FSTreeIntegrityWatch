#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

binmode(STDIN,  "utf8");
binmode(STDOUT, "utf8");
binmode(STDERR, "utf8");


# External modules
use Scalar::Util qw(blessed);
use Try::Tiny;

# FSTreeIntegrityWatch package modules
use FindBin;
use lib "$FindBin::Bin/lib/";
use FSTreeIntegrityWatch qw(set_exception_verbosity);
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
