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
    'Adler32',
    'BLAKE-224',
    'BLAKE-256',
    'BLAKE-384',
    'BLAKE-512',
    'BLAKE2',
    'BMW-224',
    'BMW-256',
    'BMW-384',
    'BMW-512',
    'CRC-8',
    'CRC-16',
    'CRC-32',
    'CRC-64',
    'CRC-CCITT',
    'CRC-OpenPGP-Armor',
    'ECHO-224',
    'ECHO-256',
    'ECHO-384',
    'ECHO-512',
    'ED2K',
    'EdonR-224',
    'EdonR-256',
    'EdonR-384',
    'EdonR-512',
    'Fugue-224',
    'Fugue-256',
    'Fugue-384',
    'Fugue-512',
    'GOST',
    'Groestl-224',
    'Groestl-256',
    'Groestl-384',
    'Groestl-512',
    'Hamsi-224',
    'Hamsi-256',
    'Hamsi-384',
    'Hamsi-512',
    'JH-224',
    'JH-256',
    'JH-384',
    'JH-512',
    'Keccak-224',
    'Keccak-256',
    'Keccak-384',
    'Keccak-512',
    'Luffa-224',
    'Luffa-256',
    'Luffa-384',
    'Luffa-512',
    'MD2',
    'MD4',
    'MD5',
    'SHA-1',
    'SHA-224',
    'SHA-256',
    'SHA-384',
    'SHA-512',
    'SHA3-224',
    'SHA3-256',
    'SHA3-384',
    'SHA3-512',
    'SHA3-SHAKE128',
    'SHA3-SHAKE256',
    'SHAvite3-224',
    'SHAvite3-256',
    'SHAvite3-384',
    'SHAvite3-512',
    'SIMD-224',
    'SIMD-256',
    'SIMD-384',
    'SIMD-512',
    'Shabal-224',
    'Shabal-256',
    'Shabal-384',
    'Shabal-512',
    'Skein-256',
    'Skein-512',
    'Skein-1024',
    'Whirlpool',
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
    $intw->load_checksums();
} catch {
    if ( blessed $_ && $_->isa('FSTreeIntegrityWatch::Exception') ) {
        die "$_\n";
    } else {
        die $_;
    }
};

print Dumper($intw->checksums());
print Dumper($intw->stored_ext_attrs());
print Dumper($intw->loaded_ext_attrs());


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
