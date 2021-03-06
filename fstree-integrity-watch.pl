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
use File::Spec;
use Getopt::Long qw(:config gnu_getopt no_ignore_case bundling);
use IO::Handle;
use List::Util qw(sum);
use Scalar::Util qw(blessed);
use Try::Tiny;

# Local FSTreeIntegrityWatch package modules
use FindBin;
use lib "$FindBin::Bin/lib/";
use FSTreeIntegrityWatch;

# External tools
my $bagit_py = "$FindBin::Bin/utils/bagit-python/bagit.py";



#
# Global configuration
#
my @files = ();
my $opts = {
    'stdin' => 0,
    'null' => 0,
    'recursive' => 0,
    'verify' => 1,
    'ext-attr-prefix' => 'fstree-integrity-watch',
    'verbose' => 1,
    'bagit' => 0,
    'bagit-py' => "$bagit_py",
};
my @opts_def = (
    '' => sub {$opts->{'stdin'} = 1},
    'null|0',
    'recursive|r!',
    'verify',
    'store|save|s' => sub { $opts->{'store'}  = 1,
                            $opts->{'verify'} = 0,
                            $opts->{'dump'}   = 0 },
    'dump|d' => sub { $opts->{'dump'}   = 1,
                      $opts->{'verify'} = 0,
                      $opts->{'store'}  = 0 },
    'dump-file|f=s',
    'dump-relative-to|relative-to|t:s',
    'algorithm|a=s@',
    'ext-attr-prefix|prefix|p=s',
    'batch-size|b=i',
    'verbose|v+',
    'quiet|q' => sub {$opts->{'verbose'} = 0},
    'bagit|g!',
    'bagit-py=s',
    'help|h',
);


#
# Subroutines
#

# Print script usage and exit.
# args
#   optional: exit value
#   optional: error message
sub print_usage_and_exit {

    my ($exit_val, $msg) = @_;

    $exit_val = 0 unless(defined($exit_val));
    my $out = \*STDERR;


    if ($opts->{'verbose'} >= 1) {

        if (defined($msg)) {
            chomp $msg;
            print $out "$msg\n\n";
        }

        print $out join("\n\n",
            join("\n\t", 'Usage:',
                join(' ',
                     "$FindBin::Script",
                     "[ { --verify | --store|--save|-s | --dump|-d } ]",
                     "[ --dump-file|-f path/to/dump_file.json ]",
                     "[ --dump-relative-to|--relative-to|-t [ path/to/dir/ ] ]",
                     "[ { --verbose|-v [ --verbose|-v ... ] | --quiet|-q } ]",
                     "[ --algorithm|-a hash_algorithm_name [ --algorithm|-a hash_algorithm_name ... ] ]",
                     "[ --ext-attr-prefix|--prefix|-p ext_attr_name_prefix ]",
                     "[ --[no-]recursive|-r ]",
                     "[ --null|-0 ]",
                     "[ --batch-size|-b size ]",
                     "[ --[no-]bagit|-g ]",
                     "[ --bagit-py path/to/bagit.py ]",
                     "--",
                     "{ - | file [ file ... ] }",
                ),
                join(' ',
                     "$FindBin::Script",
                     "[--help|-h]",
                ),
            ),
            join("\n\t", 'Example:',
                join(' ',
                     "$FindBin::Script",
                     "--save",
                     "--verbose",
                     "-a SHA-256",
                     "-a CRC-64",
                     "--recursive",
                     "--",
                     "testdata/data/dir1/",
                     "testdata/data/file6",
                ),
                join(' ',
                     "$FindBin::Script",
                     "--dump",
                     "--dump-file testdata.json",
                     "-a CRC-64",
                     "-r",
                     "testdata/",
                ),
                join(' ',
                     "$FindBin::Script",
                     "--save",
                     "--dump-file testdata.json",
                     "--dump-relative-to testdata/data/",
                     "-a CRC-64",
                     "-r",
                     "testdata/",
                ),
                join(' ',
                     "$FindBin::Script",
                     "--dump-file testdata.json",
                     "--dump-relative-to testdata/data/",
                     "-a SHA-256",
                     "-a CRC-64",
                     "-r",
                     "testdata/",
                ),
                join(' ',
                     "$FindBin::Script",
                     "--save",
                     "--dump-file testdata.json",
                     "--dump-relative-to",
                     "-a CRC-64",
                     "-r",
                     "testdata/",
                ),
                join(' ',
                     "$FindBin::Script",
                     "-a SHA-256",
                     "testdata/data/file6",
                ),
                join(' ',
                     "$FindBin::Script",
                     "-r",
                     "--bagit",
                     "--bagit-py utils/bagit-python/bagit.py",
                     "testdata/bagit/",
                ),
                join(' ',
                     "$FindBin::Script",
                     "--verify",
                     "-vv",
                     "--prefix 'file-integrity'",
                     "-a SHA-256",
                     "--algorithm Whirlpool",
                     "-a CRC-64",
                     "testdata/data/dir1/file2",
                     "testdata/data/file6",
                ),
                join(' ',
                     "find testdata/ -type f -print0",
                     "|",
                     "$FindBin::Script",
                     "--store",
                     "-vv",
                     "--null",
                     "-a CRC-32",
                     "--batch-size 20",
                     "-",
                ),
                join(' ',
                     "$FindBin::Script",
                     "--help",
                ),
            ),
            join("\n\t", 'Options:',
                join("\t\n\t\t",
                     "{ - | file [ file ... ] }",
                     "List of file paths to work on.",
                     "If dash (`-') is used instead of file path, file paths will be read from the standard input in addition."),
                join("\t\n\t\t",
                     "-0, --null",
                     "If dash (`-') argument is used to read file paths from the standard input this option changes the file paths separator from the new line characted to the NULL byte.",
                     "Useful for handling `find some/path/ -print0' outputs."),
                join("\t\n\t\t",
                     "-r, --[no-]recursive",
                     "If enabled, directories in the file list will not be skiped but traversed recursively and found files will also be added to the list.",
                     "Default is `--no-recursive'."),
                join("\t\n\t\t",
                     "--",
                     "`End of options' indicator.",
                     "Any argument after will not be consider a configuration option even though it looks like one."),
                join("\t\n\t\t",
                     "--verify",
                     "Integrity verification mode – load checksums from the extended attributes of files and compare them with newly computed checksums on the files.",
                     "The verification is done only on existing extended attributes with matching name prefix (see `--ext-attr-prefix') using selected digest algorithm(s) (see `--algorithm').",
                     "Exit with non-zero exit value in case of any error is found.",
                     "Default mode of operation."),
                join("\t\n\t\t",
                     "-s, --save, --store",
                     "Integrity storing mode – computed checksums on the files using selected digest algorithm(s) (see `--algorithm') and save them to extended attributes of the files.",
                     "Selected digest algorithm(s) (see `--algorithm') and extended attributes name prefix (see `--ext-attr-prefix') are used.",
                     "Exit with non-zero exit value in case of any error."),
                join("\t\n\t\t",
                     "-d, --dump",
                     "Integrity dumping mode – computed checksums on the files using selected digest algorithm(s) (see `--algorithm') and dump them as an integrity database in JSON format to a file (see `--dump-file').",
                     "As no filesystem extended attributes are written to / read from this mode is useful on filesystem with lack of extended attributes support.",
                     "Selected digest algorithm(s) (see `--algorithm') are used.",
                     "Exit with non-zero exit value in case of any error."),
                join("\t\n\t\t",
                     "-f, --dump-file <path/to/dump_file.json>",
                     "Path to file in JSON format the computed checksums save to / read from.",
                     "Contents of the JSON integrity database is equivalent to contents of the extended attributes contents.",
                     "In integrity storing mode (see `--save'): computed data is stored to the dump file in addition to writing them to the extended attributes.",
                     "In integrity dump mode (see `--dump'): computed data is stored to the dump file only; no extended attributes are used (useful for use with filesystem without extended attributes support).",
                     "In integrity verification mode (see `--verify'): file checksums are read from the dump file instead of reading the extended attributes (useful for use with filesystem without extended attributes support)."),
                join("\t\n\t\t",
                     "-t, --relative-to, --dump-relative-to [ <path/to/dir/> ]",
                     "Directory path to read/write file paths in the dump file (see `--dump-file') relatively to.",
                     "Dir path specification is optional. If omitted the current working directory is used."),
                join("\t\n\t\t",
                     "-a, --algorithm <algorithm_name>",
                     "Use the particular digest algorithm.",
                     "Use this option multiple times to use multipe algorithms in parallel.",
                     "Default is 'SHA-256'."),
                join("\t\n\t\t",
                     "-p, --prefix, --ext-attr-prefix <ext_attr_prefix_string>",
                     "Prefix of names of filesystem extended attributes used to store the checksums of files.",
                     "Extended attribute names on the files are assembled as: <ext_attr_prefix_string>.<digest_algorithm_name>",
                     "Default is 'fstree-integrity-watch'."),
                join("\t\n\t\t",
                     "-b, --batch-size",
                     "Defines processing batch size, i.e.",
                     "– the number of files the hash is computed from prior storing the checksums to their extended attributes,",
                     "– the number of files the hash is loaded from their extended attributes and verified against newly computed checksum prior processing next `batch-size' of files.",
                     "Use '0' to process all input files in a single batch or a positive integer to set exact batch size.",
                     "Default is '10'."),
                join("\t\n\t\t",
                     "-g, --[no-]bagit",
                     "If enabled, directories are tested to be in BagIt format (and consequently to be in valid Bagit format) in integrity verification mode.",
                     "Bagit format is validated using Python validation tool by Library of Congress.",
                     "Default is `--no-bagit'."),
                join("\t\n\t\t",
                     "--bagit-py",
                     "Path to `bagit.py' BagIt format Python validation tool.",
                     "Use `--bagit-py bagit.py' to use system wide (i.e. in \$PATH available) installation of bagit.py.",
                     "Default is 'utils/bagit-python/bagit.py' relatively to this executable path."),
                join("\t\n\t\t",
                     "-v, --verbose",
                     "Set verbosity level. Multiple uses of this option increase the detail of info messages.",
                     "level 1 (default): print warning and error messages",
                     "level 2: in addition print processing info messages",
                     "level 3: in addition print stack trace in case of errors",
                     "level 4: in addition print script configuration summary at start up"),
                join("\t\n\t\t",
                     "-q, --quiet",
                     "Silent mode. Sets verbosity level 0 discarding any info and error messages.",
                     "Non-zero exit value of the script indicates error."),
                join("\t\n\t\t",
                     "-h, --help",
                     "Print the usage info and exit."),
            ),
            join("\n\t",
                'Valid digest algorithms:',
                join(' ', sort keys %{FSTreeIntegrityWatch::Digest->algorithms()})
            )
        )."\n";

    }

    exit($exit_val);

}

# Check validity of provided arguments. In case of an error exit with help
# message.
sub check_options {

    # path argument of the `dump-relative-to' option is optional; if no argument
    # is specified use the current directory
    $opts->{'dump-relative-to'} = File::Spec->curdir()
            if (defined($opts->{'dump-relative-to'}) and $opts->{'dump-relative-to'} eq '');

    print_usage_and_exit() if ($opts->{'help'});
    print_usage_and_exit(2, 'No files to work on.') unless (scalar(@files) > 0);
    print_usage_and_exit(3, 'Invalid batch size: '.$opts->{'batch-size'})
            if (defined($opts->{'batch-size'}) and $opts->{'batch-size'} < 0);
    print_usage_and_exit(4, "Invalid directory path of the `--dump-relative-to' option: ".$opts->{'dump-relative-to'})
            if (defined($opts->{'dump-relative-to'}) and not -d $opts->{'dump-relative-to'});
    print_usage_and_exit(5, "Use of `--dump-file' option is mandatory in `--dump' mode.")
            if ($opts->{'dump'} and not defined($opts->{'dump-file'}));
    print_usage_and_exit(6, "'".$opts->{'bagit-py'}."' is not valid path to executable `bagit.py' validation tool.")
            if (defined($opts->{'bagit-py'}) and not (-e $opts->{'bagit-py'} or $opts->{'bagit-py'} eq 'bagit.py'));

}

# Print processing warning message if the current verbosity level instructs us
# to do so.
# args
#   message to print
sub print_warning {

    my $msg = shift @_;

    chomp $msg;

    IO::Handle::printflush STDERR "$msg\n" if ($opts->{'verbose'} >= 1);

}

# Print processing info message if the current verbosity level instructs us to
# do so.
# args
#   message to print
sub print_info {

    my $msg = shift @_;

    chomp $msg;

    IO::Handle::printflush STDOUT "$msg\n" if ($opts->{'verbose'} >= 2);

}



#
# Main
#

# Check and process command line options.
try {

    # Parse command line.
    GetOptions ($opts, @opts_def)
        or print_usage_and_exit(1, "Error in command line arguments");

    @files = @ARGV; # Use file paths from the command line.
    if ($opts->{'stdin'}) { # Use file paths from STDIN in configured.
        print_info("Reading files list from the standard input...");
        my $orig_separator = $/;
        # Allow NULL separated strings if configured – useful for handling `find
        # some/dir/ -print0' outputs.
        $/ = "\0" if ($opts->{'null'});
        while (my $fp = <STDIN>) {
            chomp $fp;
            push(@files, $fp);
        }
        $/ = $orig_separator;
        print_info("Reading files list from the standard input done.");
    }

    # Check the configuration.
    check_options();

} catch {
    if ( blessed $_ && $_->isa('FSTreeIntegrityWatch::Exception') ) {
        die "$_\n";
    } else {
        die $_;
    }
};

# Setup FSTreeIntegrityWatch according to our configuration.
print_info("Building files list...");
my $intw = FSTreeIntegrityWatch->new(
    'ext_attr_name_prefix' => $opts->{'ext-attr-prefix'},
    'files'                => [ @files ],
    'recursive'            => $opts->{'recursive'},
    'bagit_mode'           => $opts->{'bagit'},
    'bagit_py'             => $opts->{'bagit-py'},
);
print_info("Building files list done.");
$intw->algorithms($opts->{'algorithm'}) if (defined($opts->{'algorithm'}));
$intw->batch_size($opts->{'batch-size'}) if (defined($opts->{'batch-size'}));
$intw->verbosity($opts->{'verbose'} > 2 ? 2 : $opts->{'verbose'});
$intw->exception_verbosity(1) if ($opts->{'verbose'} >= 3);

# Print internal configuration state in the very verbose mode.
if ($opts->{'verbose'} >= 4) {
    print STDERR join("\n\t",
                      'Options:',
                      map {
                          sprintf("'%s': '%s'",
                                  $_,
                                  ref ($opts->{$_}) eq 'ARRAY'
                                    ? join(', ', @{$opts->{$_}})
                                      : $opts->{$_})
                      } sort keys %$opts)."\n";
    print STDERR join("\n\t", 'File paths entered by the user:', sort @files)."\n";
    print STDERR join("\n\t", 'File paths to work with:', sort @{$intw->files()})."\n";
    print STDERR "\n";
}

my $rv = 0;
try {
    # Mode of operation – verify existing saved checksums or save the current
    # state?
    if ($opts->{'verify'}) { # Verification mode

        my $dfc;
        if (defined($opts->{'dump-file'})) {
            $dfc = $intw->verify_checksums($opts->{'dump-file'}, $opts->{'dump-relative-to'});
        } else {
            $dfc = $intw->verify_checksums();
        }

        if (scalar(keys %$dfc) > 0) {
            # Exit with error exit code only in case of error, warnings are OK.
            $rv = sum(map { exists($dfc->{$_}->{'error'}) ? 1 : 0 } keys %$dfc) > 0 ? 1 : 0;
            # Print verification errors and warnings unless in silent mode.
            # Otherwise script exit value is error state indication.
            if ($opts->{'verbose'} >= 1) {
                foreach my $filename (sort keys %$dfc) {
                    foreach my $alg (sort keys %{$dfc->{$filename}->{'error'}}) {
                        if ($alg eq 'BagIt') {
                            my $rv   = $dfc->{$filename}->{'error'}->{$alg}->{'return_value'};
                            my $desc = $dfc->{$filename}->{'error'}->{$alg}->{'description'};
                            IO::Handle::printflush STDERR sprintf("Invalid BagIt found: path '%s' – validation tool return value '%d' – error description '%s'\n",
                                                                  $filename, $rv, $desc);
                        } else {
                            my $ecsum    = $dfc->{$filename}->{'error'}->{$alg}->{'expected_checksum'};
                            my $ecsum_ts = $dfc->{$filename}->{'error'}->{$alg}->{'expected_checksum_stored_at'};
                            my $ccsum    = $dfc->{$filename}->{'error'}->{$alg}->{'computed_checksum'};
                            IO::Handle::printflush STDERR sprintf("File corruption detected: file '%s' – algorithm '%s' – expected checksum '%s' (stored at '%s') – current checksum '%s'\n",
                                                                  $filename, $alg, $ecsum, $ecsum_ts, $ccsum);
                        }
                    }
                    foreach my $alg (sort keys %{$dfc->{$filename}->{'warning'}}) {
                        my $msg = $dfc->{$filename}->{'warning'}->{$alg}->{'message'};
                        IO::Handle::printflush STDERR sprintf("File integrity verification warning: file '%s' – %s\n",
                                                              $filename, $msg);
                    }
                }
            }
        }

    } elsif ($opts->{'dump'}) { # Dump mode

        $intw->dump_checksums($opts->{'dump-file'}, $opts->{'dump-relative-to'});

    } else { # Save mode

        $intw->store_checksums();
        $intw->dump_stored_attrs_as_json_to_file($opts->{'dump-file'},
                                                 $opts->{'dump-relative-to'}) if (defined($opts->{'dump-file'}));

    }
} catch {
    if ($opts->{'verbose'} >= 1) {
        if ( blessed $_ && $_->isa('FSTreeIntegrityWatch::Exception') ) {
            die "$_\n";
        } else {
            die $_;
        }
    } else {
        exit($rv == 0 ? 1 : $rv);
    }
};

exit($rv);


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
