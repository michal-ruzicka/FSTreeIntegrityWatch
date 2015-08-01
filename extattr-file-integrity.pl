#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

binmode(STDIN,  "utf8");
binmode(STDOUT, "utf8");
binmode(STDERR, "utf8");

# Error prints
use Carp qw(carp cluck croak confess);


# External modules
use Scalar::Util qw(blessed);
use Try::Tiny;

# FSTreeIntegrityWatch package
use FindBin;
use lib "$FindBin::Bin/perllib/";
use FSTreeIntegrityWatch qw(:standard);


#
# Global configuration
#
my $file = "$FindBin::Bin/testdata/data/file6";
FSTreeIntegrityWatch::set_stack_trace_prints('1'); # Be verbose about errors.


#
# Main
#
print "Working on file: '$file'\n";

try {
    print get_file_checksum('SHA-2', $file)."\n";
} catch {
    if ( blessed $_ && $_->isa('FSTreeIntegrityWatch::Exception') ) {
        croak "Exception handling:\n".$_;
    } else {
        croak "Exception handling:\n".$_;
    }
};


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
