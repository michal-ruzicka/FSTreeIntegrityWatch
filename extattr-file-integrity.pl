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
use FSTreeIntegrityWatch;



#
# Global configuration
#
my $file = "$FindBin::Bin/testdata/data/file6";
my $alg = 'SHA-1';
my $attr = $alg;
my $exception_verbosity = '1';


#
# Main
#
my $fstiw = FSTreeIntegrityWatch->new(
    'exception_verbosity' => $exception_verbosity,
    'algorithms' => [ "$alg" ],
    'files' => [ "$file" ],
);

printf("%s: %s\n", 'exception_verbosity', $fstiw->exception_verbosity());
printf("%s: %s\n", 'algorithms', join('; ', @{$fstiw->algorithms()}));
printf("%s: %s\n", 'files', join('; ', @{$fstiw->files()}));

try {
    my $results = $fstiw->store_checksums();
    foreach my $file (sort keys %$results) {
        foreach my $alg (sort keys %{$results->{$file}}) {
            printf("Stored '%s' hash '%s' as the extended attribute '%s' at '%s'.\n",
                    $alg, $results->{$file}->{$alg}->{'checksum'},
                    $results->{$file}->{$alg}->{'attr_name'}, $file);
        }
    }
} catch {
    if ( blessed $_ && $_->isa('FSTreeIntegrityWatch::Exception') ) {
        die "$_\n";
    } else {
        die $_;
    }
};


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
