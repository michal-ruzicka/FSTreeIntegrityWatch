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
use FSTreeIntegrityWatch qw(:standard);



#
# Global configuration
#
my $file = "$FindBin::Bin/testdata/data/file6";
FSTreeIntegrityWatch::set_exception_verbosity('1');


#
# Main
#
print "Working on file: '$file'\n";

try {
    print get_file_checksum('SHA-1', $file)."\n";
} catch {
    if ( blessed $_ && $_->isa('FSTreeIntegrityWatch::Exception') ) {
        die "$_\n";
    } else {
        die $_;
    }
};


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
