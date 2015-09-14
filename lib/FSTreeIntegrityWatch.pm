
package FSTreeIntegrityWatch;

use strict;
use warnings;
use utf8;


# Package modules
use FSTreeIntegrityWatch::BagIt;
use FSTreeIntegrityWatch::Digest;
use FSTreeIntegrityWatch::Exception;
use FSTreeIntegrityWatch::ExtAttr;
use FSTreeIntegrityWatch::Tools qw(
    decode_locale_if_necessary
    get_iso8601_formated_datetime
);

# External modules
use feature qw(say);
use File::Basename;
use File::Find;
use File::Spec;
use JSON;
use List::Compare;
use List::MoreUtils qw(uniq);
use Try::Tiny;


# Use Class::Tiny for class construction.
use subs 'exception_verbosity'; # Necessary to provide our own 'exception_verbosity' accessor.
use subs 'verbosity'; # Necessary to provide our own 'verbosity' accessor.
use subs 'files'; # Necessary to provide our own 'files' accessor.
use subs 'recursive'; # Necessary to provide our own 'recursive' accessor.
use subs 'batch_size'; # Necessary to provide our own 'recursive' accessor.
use Class::Tiny {
    'exception_verbosity'      => 0,
    'verbosity'                => 0,
    'ext_attr_name_prefix'     => 'fstree-integrity-watch',
    'algorithms'               => sub { [ "SHA-256" ] },
    'files'                    => sub { [ ] },
    'recursive'                => 0,
    'batch_size'               => 10,
    'bagit_mode'               => 0,
    'bagit_py'                 => 'bagit.py',
    'checksums'                => sub { { } },
    'stored_ext_attrs'         => sub { { } },
    'loaded_ext_attrs'         => sub { { } },
    'validated_bagits'         => sub { { } },
    'detected_file_corruption' => sub { { } },
};



# Constructor hook validates parameters.
sub BUILD {

    my ($self, $args) = @_;

    $self->exception_verbosity($self->{'exception_verbosity'}) if (defined($self->{'exception_verbosity'}));
    $self->verbosity($self->{'verbosity'}) if (defined($self->{'verbosity'}));
    $self->files($self->{'files'}) if (defined($self->{'files'}));

}

# Enable/disable stack trace as part of the standard exception error message.
# args
#   1 or 0 (default) to enable/disable stack trace in exception error messages
# throws
#   FSTreeIntegrityWatch::Exception::Config in case of an invalid argument
sub exception_verbosity {

    my $self = shift @_;

    if (@_) {

        my $value = shift @_;

        if ($value =~ /^[0-1]$/) {
            $FSTreeIntegrityWatch::Exception::exception_verbosity = $value;
            return $self->{'exception_verbosity'} = $value;
        } else {
            my $defaults = Class::Tiny->get_all_attribute_defaults_for( ref $self );
            $self->{'exception_verbosity'} = $defaults->{'exception_verbosity'};
            $self->exp('Config', "Invalid 'exception_verbosity' configuration value, use '0' or '1'.");
        }

    } elsif ( exists $self->{'exception_verbosity'} ) {

        return $self->{'exception_verbosity'};

    } else {

        my $defaults = Class::Tiny->get_all_attribute_defaults_for( ref $self );
        return $self->{'exception_verbosity'} = $defaults->{'exception_verbosity'};

    }

}

# Set/get verbosity of info prints during processing.
# args
#   int >= 0 set verbosity level
#     level 0 (default): no printing, exceptions with included error messages are thrown
#     level 1: print processing warning and error messages
#     level 2: in addition print processing info messages
# throws
#   FSTreeIntegrityWatch::Exception::Config in case of an invalid argument
sub verbosity {

    my $self = shift @_;

    if (@_) {

        my $value = shift @_;

        if ($value =~ /^[0-2]$/) {
            return $self->{'verbosity'} = $value;
        } else {
            my $defaults = Class::Tiny->get_all_attribute_defaults_for( ref $self );
            $self->{'verbosity'} = $defaults->{'verbosity'};
            $self->exp('Config', "Invalid 'verbosity' configuration value, use integer between '0' and '2'.");
        }

    } elsif ( exists $self->{'verbosity'} ) {

        return $self->{'verbosity'};

    } else {

        my $defaults = Class::Tiny->get_all_attribute_defaults_for( ref $self );
        return $self->{'verbosity'} = $defaults->{'verbosity'};

    }

}

# Set/get list of files to work on. Duplicate entries are eliminated from the
# list.
# args
#   array ref of file paths to work on
sub files {

    my $self = shift @_;

    if (@_) {

        my $files = shift @_;

        @$files = map { File::Spec->canonpath(File::Spec->rel2abs($_)) } @$files;

        if ($self->{'recursive'}) {
            my $find_dirs = [];
            foreach my $f (@$files) {
                push(@$find_dirs, $f) if (-d $f);
            }
            my $find_files = {};
            find({ follow => 1,
                   follow_skip => 2,
                   no_chdir => 1,
                   wanted => sub {
                       $find_files->{File::Spec->canonpath(File::Spec->rel2abs(decode_locale_if_necessary($File::Find::name)))}++;
                   },
                 }, @$find_dirs) if (scalar(@$find_dirs) > 0);
            push(@$files, keys %$find_files);
        }

        @$files = uniq sort @$files;

        return $self->{'files'} = $files;

    } elsif ( exists $self->{'files'} ) {

        return $self->{'files'};

    } else {

        my $defaults = Class::Tiny->get_all_attribute_defaults_for( ref $self );
        return $self->{'files'} = $defaults->{'files'};

    }

}

# Set/get directory behaviour.
# args
#   0 (default) to skip directories in the list of file path to work on or
#   1 to traverse directories recursively and add found files to the list of
#     file paths to work on
# throws
#   FSTreeIntegrityWatch::Exception::Config in case of an invalid argument
sub recursive {

    my $self = shift @_;

    if (@_) {

        my $value = shift @_;

        if ($value =~ /^[01]$/) {
            return $self->{'recursive'} = $value;
        } else {
            my $defaults = Class::Tiny->get_all_attribute_defaults_for( ref $self );
            $self->{'recursive'} = $defaults->{'recursive'};
            $self->exp('Config', "Invalid 'recursive' configuration value, use '0' or '1'.");
        }

    } elsif ( exists $self->{'recursive'} ) {

        return $self->{'recursive'};

    } else {

        my $defaults = Class::Tiny->get_all_attribute_defaults_for( ref $self );
        return $self->{'recursive'} = $defaults->{'recursive'};

    }

}

# Set/get number of input files processed in one storing/verification batch.
# args
#   0 process all the inputs in one bach or
#   number > 0 (default 3) to process given number of files at once
# throws
#   FSTreeIntegrityWatch::Exception::Config in case of an invalid argument
sub batch_size {

    my $self = shift @_;

    if (@_) {

        my $value = shift @_;

        if ($value =~ /^\d+$/) {
            return $self->{'batch_size'} = $value;
        } else {
            my $defaults = Class::Tiny->get_all_attribute_defaults_for( ref $self );
            $self->{'batch_size'} = $defaults->{'batch_size'};
            $self->exp('Config', "Invalid 'batch_size' configuration value, use '0' or positive number.");
        }

    } elsif ( exists $self->{'batch_size'} ) {

        return $self->{'batch_size'};

    } else {

        my $defaults = Class::Tiny->get_all_attribute_defaults_for( ref $self );
        return $self->{'batch_size'} = $defaults->{'batch_size'};

    }

}

# Throw some of the FSTreeIntegrityWatch::Exception exceptions following
# exception verbosity setting.
# args
#   exception type, i.e. FSTreeIntegrityWatch::Exception::$type
#     or undef to throw generic FSTreeIntegrityWatch::Exception.
#   exception throw() arguments
sub exp {

    my $self = shift @_;
    my $type = shift @_;
    my @args = @_;

    # If only one argument is given it is an error message.
    @args = ('message' => $args[0]) if (scalar(@args) == 1);
    # Force the use of our show stack trace setting.
    push(@args, show_trace => $self->exception_verbosity());

    # Throw exception of requested type.
    my $class = 'FSTreeIntegrityWatch::Exception'.(defined($type) ? "::$type" : '');

    $class->throw(@args);

}

# Print processing warning message if the current verbosity level instructs us
# to do so.
# args
#   message to print
sub print_warning {

    my $self = shift @_;
    my $msg = shift @_;

    chomp $msg;

    say STDERR "$msg" if ($self->verbosity >= 1);

}

# Print processing info message if the current verbosity level instructs us to
# do so.
# args
#   message to print
sub print_info {

    my $self = shift @_;
    my $msg = shift @_;

    chomp $msg;

    say "$msg" if ($self->verbosity >= 2);

}

# Create and return a new FSTreeIntegrityWatch class instance, clone its
# configuration (i.e. exception_verbosity, verbosity, ext_attr_name_prefix,
# files, algorithms and recursive attributes settings etc., but _not_ results
# attributes such as checksums, stored_ext_attrs etc.) from the current one.
# returns
#   the new instance with the cloned configuration
sub clone_configuration {

    my $self = shift @_;

    my $clone = FSTreeIntegrityWatch->new(
        'exception_verbosity'  => $self->exception_verbosity(),
        'verbosity'            => $self->verbosity(),
        'ext_attr_name_prefix' => $self->ext_attr_name_prefix(),
        'algorithms'           => [ @{$self->algorithms()} ],
        'files'                => [ @{$self->files()} ],
        'recursive'            => 0, # Do not traverse the filesystem and
                                     # possibly modify files array when cloning
                                     # configuration!
        'batch_size'           => $self->batch_size(),
        'bagit_mode'           => $self->bagit_mode(),
        'bagit_py'             => $self->bagit_py(),
    );
    $clone->recursive($self->recursive()); # But clone the recursion setting
                                           # finally.

    return $clone;

}

# For $self->files() computes their checksums using all the $self->algorithms()
# and dumps the results as an integrity database in JSON format to the given
# file.
# args
#   dump_file   path to JSON file to save the data to
#   relative_to dir path to write file paths in the dump relatively to
#               OR undef to insert absolute paths in the dump
# throws
#   FSTreeIntegrityWatch::Exception or their subclasses in case of errors during
#   the processing.
sub dump_checksums {

    my $self = shift @_;
    my $dump_file = shift @_;
    my $relative_to = shift @_;

    $self->exp('Param', "No dumpfile specified.") unless (defined($dump_file));

    $self->print_info("Dumping checksums to '$dump_file'...");

    my $csum  = $self->checksums;
    my $scsum = {};

    my @inputs = @{$self->files};
    my $batch_size = $self->batch_size == 0 ? scalar(@inputs) : $self->batch_size;
    while (my @files = splice(@inputs, 0, $batch_size)) {

        my $config = $self->clone_configuration();
           $config->recursive(0); # Do not modify the file list.
           $config->files([@files]);

        my $digest  = FSTreeIntegrityWatch::Digest->new($config);
        my $batch_csum  = $digest->compute_checksums();
        foreach my $f (keys %$batch_csum) {
            $csum->{$f} = $batch_csum->{$f};
        }

        my $cs        = $config->checksums();
        my $attr_pref = $config->ext_attr_name_prefix();
        my $sa = {};

        foreach my $filename (keys %$cs) {
            foreach my $alg (keys %{$cs->{$filename}}) {

                my $checksum = $cs->{$filename}->{$alg}->{'checksum_value'};

                my $attr_name = sprintf("%s.%s", $attr_pref, $alg);
                my $attr_value = to_json({
                    'storedAt' => get_iso8601_formated_datetime(),
                    'checksum' => $checksum,
                });

                $config->print_info("storing '$alg' checksum '$checksum' to JSON dump of extended attribute '$attr_name' on '$filename'");

                $sa->{$filename}->{$alg}->{'stored_at'}  = time;
                $sa->{$filename}->{$alg}->{'attr_name'}  = $attr_name;
                $sa->{$filename}->{$alg}->{'attr_value'} = $attr_value;

            }
        }

        foreach my $f (keys %$sa) {
            $scsum->{$f} = $sa->{$f};
        }

    }

    my $dumper = $self->clone_configuration();
    $dumper->stored_ext_attrs($scsum);
    $dumper->dump_stored_attrs_as_json_to_file($dump_file,
                                               $relative_to);

    $self->print_info("Dumping checksums done.");

    return $scsum;

}

# For $self->files() computes their checksums using all the $self->algorithms()
# and stores the results to the extended attributes of the files.
# returns
#   stored_ext_attrs hash ref of the used context
# throws
#   FSTreeIntegrityWatch::Exception or their subclasses in case of errors during
#   processing.
sub store_checksums {

    my $self = shift @_;

    $self->print_info("Storing checksums...");

    my $csum  = $self->checksums;
    my $scsum = $self->stored_ext_attrs;

    my @inputs = @{$self->files};
    my $batch_size = $self->batch_size == 0 ? scalar(@inputs) : $self->batch_size;
    while (my @files = splice(@inputs, 0, $batch_size)) {

        my $config = $self->clone_configuration();
           $config->recursive(0); # Do not modify the file list.
           $config->files([@files]);

        my $digest  = FSTreeIntegrityWatch::Digest->new($config);
        my $batch_csum  = $digest->compute_checksums();
        foreach my $f (keys %$batch_csum) {
            $csum->{$f} = $batch_csum->{$f};
        }

        my $extattr = FSTreeIntegrityWatch::ExtAttr->new($config);
        my $batch_scsum = $extattr->store_checksums();
        foreach my $f (keys %$batch_scsum) {
            $scsum->{$f} = $batch_scsum->{$f};
        }

    }

    $self->print_info("Storing checksums done.");

    return $scsum;

}

# Returns $self->stored_ext_attrs in integrity database JSON format.
# args
#   relative_to dir path to write file paths in the dump relatively to
#   or undef to insert absolute paths in the dump
# returns
#   integrity database created from $self->stored_ext_attrs as
#   pretty printed JSON
sub get_stored_attrs_as_json {

    my $self = shift @_;
    my $relative_to = shift @_;

    if (defined($relative_to)) {
        $relative_to = File::Spec->canonpath(File::Spec->rel2abs($relative_to));
        $relative_to = dirname($relative_to) if (not -d $relative_to);
    }

    my $scsum = $self->stored_ext_attrs;
    my $scdump = {};

    foreach my $f (keys %$scsum) {
        foreach my $a (keys %{$scsum->{$f}}) {
            my $n = $scsum->{$f}->{$a}->{'attr_name'};
            my $v = from_json($scsum->{$f}->{$a}->{'attr_value'});
            my $of = (defined $relative_to) ? File::Spec->abs2rel($f, $relative_to) : $f;
            $scdump->{$of}->{$n} = $v;
        }
    }

    return to_json($scdump, { pretty => 1 });

}

# Stores $self->stored_ext_attrs as an integrity database in JSON format to
# the given file.
# args
#   dump_file   path to JSON file to save the data to
#   relative_to dir path to write file paths in the dump relatively to
#               OR undef to insert absolute paths in the dump
# throws
#   FSTreeIntegrityWatch::Exception in case of file manipulation error
#   FSTreeIntegrityWatch::Exception::Param if no dump_file is specified
sub dump_stored_attrs_as_json_to_file {

    my $self = shift @_;
    my $dump_file = shift @_;
    my $relative_to = shift @_;

    $self->exp('Param', "No dumpfile specified.") unless (defined($dump_file));

    my $json_dump = $self->get_stored_attrs_as_json($relative_to);

    $self->print_info("Saving integrity database in UTF-8 encoded JSON format to file '$dump_file'...");

    open(DUMP, ">:encoding(UTF-8)", $dump_file)
        or $self->exp(undef, "open($dump_file) failed: ".decode_locale_if_necessary($!));
    print DUMP $json_dump;
    close(DUMP);

    $self->print_info("Saving integrity database done.");

}

# Returns data from integrity database in JSON format produced
# by $self->get_stored_attrs_as_json() in $self->stored_ext_attrs format.
# args
#   json_dump   JSON dump of integrity checksums produced by
#               $self->get_stored_attrs_as_json()
#   relative_to dir path to interpret file paths in the dump
#               relatively to
#               OR undef to use unmodified paths from the dump
#   files       array ref to list of file paths to use form the JSON dump (other
#               files are filtered out)
#               OR undef to work with all the files from the JSON dump
# returns
#   hash ref in $self->stored_ext_attrs format
sub get_loaded_attrs_from_json {

    my $self = shift @_;
    my $json_dump = shift @_;
    my $relative_to = shift @_;
    my $files = shift @_;

    if (defined($relative_to)) {
        $relative_to = File::Spec->canonpath(File::Spec->rel2abs($relative_to));
        $relative_to = dirname($relative_to) if (not -d $relative_to);
    }

    $self->print_info("Loading checksums from JSON dump ".(defined($relative_to) ? "relatively to '$relative_to'" : '')."...");

    my $files_hash;
    if (defined($files)) {
        foreach my $abs_fn (@$files) {
            $files_hash->{$abs_fn}++;
        }
    }

    my $la        = {};
    my $attr_pref = $self->ext_attr_name_prefix();

    my $prefix_name_re = qr/^(\Q$attr_pref\E)\.(\S+)$/;

    my $json = from_json($json_dump);

    foreach my $f (keys %$json) {

        my $abs_fn = defined($relative_to) ? File::Spec->canonpath(File::Spec->rel2abs($f, $relative_to)) : $f;

        if (defined($files)) {
            next unless(exists($files_hash->{$abs_fn}));
        }

        foreach my $n (keys %{$json->{$f}}) {

            my $v = $json->{$f}->{$n};

            if ($n =~ $prefix_name_re) {

                my ($prefix, $alg) = ($1, $2);

                $self->print_info("loading checksum from JSON dump of attribute '$n' of '$f'");

                $la->{$abs_fn}->{$alg}->{'loaded_at'}  = time;
                $la->{$abs_fn}->{$alg}->{'attr_name'}  = $n;
                $la->{$abs_fn}->{$alg}->{'attr_value'} = to_json($v);

            }

        }

    }

    $self->print_info("Loading checksums from JSON dump done.");

    return $la;

}

# Returns data from file with integrity database in JSON format produced by
# $self->dump_stored_attrs_as_json_to_file() in $self->stored_ext_attrs format.
# args
#   dump_file  path to JSON dump file to load the data from
#   relative_to dir path to interpret file paths in the dump
#               relatively to
#               OR undef to use unmodified paths from the dump
#   files       array ref to list of file paths to use form the JSON dump (other
#               files are filtered out)
#               OR undef to work with all the files from the JSON dump
# returns
#   hash ref in $self->stored_ext_attrs format
# throws
#   FSTreeIntegrityWatch::Exception::Param if no dump_file is specified
sub get_loaded_attrs_from_json_file {

    my $self = shift @_;
    my $dump_file = shift @_;
    my $relative_to = shift @_;
    my $files = shift @_;

    $self->exp('Param', "No dumpfile specified.") unless (defined($dump_file));

    $self->print_info("Loading integrity database in JSON format from file '$dump_file'...");

    open(DUMP, "<:encoding(UTF-8)", $dump_file)
        or $self->exp(undef, "open($dump_file) failed: ".decode_locale_if_necessary($!));
    my @json_lines = <DUMP>;
    my $json_dump = join('', @json_lines);
    close(DUMP);

    $self->print_info("Loading integrity database done.");

    return $self->get_loaded_attrs_from_json($json_dump, $relative_to, $files)

}

# For $self->files() loads their saved checksums from the extended attributes.
# returns
#   loaded_ext_attrs hash ref of the used context
# throws
#   FSTreeIntegrityWatch::Exception or their subclasses in case of errors during
#   processing.
sub load_checksums {

    my $self = shift @_;

    $self->print_info("Loading checksums...");

    my $extattr = FSTreeIntegrityWatch::ExtAttr->new($self);
    my $lcsums = $extattr->load_checksums();

    $self->print_info("Loading checksums done.");

    return $lcsums;

}

# For $self->files() loads their saved checksums from the extended attributes,
# recalculates the checksums using $self->algorithms() and compare the loaded
# checksums with the newly computed checksums.
# args
#   json_file  JSON dump file with integrity checksums produced by
#              $self->dump_stored_attrs_as_json_to_file() to use instead of
#              reading extended attributes form the filesystem
#              OR undef to read extended attributes form the filesystem
#   json_relative_to dir path to interpret file paths in the dump
#                    relatively to
#                    OR undef to use unmodified paths from the dump
# returns
#   detected_file_corruption hash ref of the used context
# throws
#   FSTreeIntegrityWatch::Exception or their subclasses in case of errors during
#   processing.
sub verify_checksums {

    my $self = shift @_;
    my $json_file = shift @_;
    my $json_relative_to = shift @_;

    $self->print_info("Verifying checksums...");

    my $dfc = $self->detected_file_corruption();

    my @inputs = @{$self->files};
    my $batch_size = $self->batch_size == 0 ? scalar(@inputs) : $self->batch_size;
    while (my @files = splice(@inputs, 0, $batch_size)) {

        my $config = $self->clone_configuration();
           $config->recursive(0); # Do not modify the file list.
           $config->files([@files]);

        try {

            my $loaded_checksums;
            if (defined($json_file)) {
                $loaded_checksums = $self->get_loaded_attrs_from_json_file($json_file, $json_relative_to, [@files]);
            } else {
                my $extattr = FSTreeIntegrityWatch::ExtAttr->new($config);
                $loaded_checksums = $extattr->load_checksums();
            }

            # It is not necessary to computed checksums for files/algorithm we
            # do not know the previous values to compare with. Thus, prepare
            # a new context containing only these files and filters current
            # algorithms to the ones used on these files.
            my @used_files = ();
            my $used_algs = {};
            foreach my $filepath (keys %$loaded_checksums) {
                push(@used_files, $filepath);
                foreach my $alg (keys %{$loaded_checksums->{$filepath}}) {
                    $used_algs->{$alg}++;
                }
            }
            my $lc = List::Compare->new([keys %$used_algs], $config->algorithms());
            my @used_algorithms = $lc->get_intersection();
            my $digest_ctx = $config->clone_configuration();
               $digest_ctx->recursive(0); # Do not modify the file list.
               $digest_ctx->files([@used_files]);
               $digest_ctx->algorithms([@used_algorithms]);
            my $digest = FSTreeIntegrityWatch::Digest->new($digest_ctx);
            my $computed_checksums = $digest->compute_checksums();

            foreach my $filename (sort keys %$loaded_checksums) {
                foreach my $alg (sort keys %{$loaded_checksums->{$filename}}) {

                    my $attr_value = from_json($loaded_checksums->{$filename}->{$alg}->{'attr_value'});
                    my $lcsum      = $attr_value->{'checksum'};
                    my $lcsum_time = $attr_value->{'storedAt'};

                    if (exists($computed_checksums->{$filename}->{$alg})) {

                        my $ccsum = $computed_checksums->{$filename}->{$alg}->{'checksum_value'};

                        unless ($lcsum eq $ccsum) {
                            $dfc->{$filename}->{'error'}->{$alg}->{'verified_at'}       = time;
                            $dfc->{$filename}->{'error'}->{$alg}->{'expected_checksum'} = $lcsum;
                            $dfc->{$filename}->{'error'}->{$alg}->{'computed_checksum'} = $ccsum;
                            $dfc->{$filename}->{'error'}->{$alg}->{'expected_checksum_stored_at'} = $lcsum_time;
                        }

                    } else {

                        $dfc->{$filename}->{'warning'}->{$alg}->{'message'}
                            = sprintf("Unknown algorithm '%s', checksum '%s' not verified.",
                                      $alg, $lcsum);

                    }

                }
            }

            if ($config->bagit_mode()) {

                my $bagit = FSTreeIntegrityWatch::BagIt->new($config);
                my $validated_bagits = $bagit->validate();

                foreach my $filename (sort keys %$validated_bagits) {
                    $dfc->{$filename}->{'error'}->{'BagIt'} = $validated_bagits->{$filename} unless ($validated_bagits->{$filename}->{'is_valid'});
                }

            }

        } catch {
            $config->exp(undef, "Verification of checksums failed: $_");
        };

    }

    $self->print_info("Verifying checksums done.");

    return $dfc;

}


1;


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
