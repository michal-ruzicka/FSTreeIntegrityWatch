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
use Data::Dumper;
use Scalar::Util qw(blessed);
use Try::Tiny;

# Local FSTreeIntegrityWatch package modules
use FindBin;
use lib "$FindBin::Bin/lib/";
use FSTreeIntegrityWatch;



#
# Global configuration
#
my @files = (
    "$FindBin::Bin/testdata/data/dir2/file3",
    "$FindBin::Bin/testdata/data/dir2/file4",
    "$FindBin::Bin/testdata/data/file6",
);
my @algs = (
    'SHA-1',
    'SHA-512',
);
my $ext_attr_name_prefix = 'test-ext-attr-prefix';
my $exception_verbosity = '1';


#
# Main
#
my $intw = FSTreeIntegrityWatch->new(
    'exception_verbosity'  => $exception_verbosity,
    'ext_attr_name_prefix' => $ext_attr_name_prefix,
    'algorithms'           => [ @algs ],
    'files'                => [ @files ],
);

printf("%s: %s\n", 'exception_verbosity', $intw->exception_verbosity());
printf("%s: %s\n", 'algorithms', join('; ', @{$intw->algorithms()}));
printf("%s: %s\n", 'files', join('; ', @{$intw->files()}));

try {
    $intw->store_checksums();
    print Dumper($intw->checksums());
    print Dumper($intw->stored_ext_attrs());
} catch {
    if ( blessed $_ && $_->isa('FSTreeIntegrityWatch::Exception') ) {
        die "$_\n";
    } else {
        die $_;
    }
};


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
