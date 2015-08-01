#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

binmode(STDIN,  "utf8");
binmode(STDOUT, "utf8");
binmode(STDERR, "utf8");


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

print get_file_checksum('SHA-1', $file)."\n";


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
