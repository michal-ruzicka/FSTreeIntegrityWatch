
package FSTreeIntegrityWatch::Digest;

use strict;
use warnings;
use utf8;


# Package modules
use FSTreeIntegrityWatch::Tools qw(decode_locale_if_necessary);

# External modules
use Digest;
use Module::Load;
use Try::Tiny;


# Use Class::Tiny for class construction.
use Class::Tiny 1.001 qw(context), { # BUILDARGS method was introduced in version 1.001 of the module.
    'algorithms' => sub { {
        "Adler32" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Adler32' ],
        },
        "BLAKE-224" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::BLAKE',  '224' ],
        },
        "BLAKE-256" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::BLAKE',  '256' ],
        },
        "BLAKE-384" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::BLAKE',  '384' ],
        },
        "BLAKE-512" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::BLAKE',  '512' ],
        },
        "BLAKE2" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::BLAKE2',  'blake2b' ],
        },
        "BMW-224" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::BMW',  '224' ],
        },
        "BMW-256" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::BMW',  '256' ],
        },
        "BMW-384" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::BMW',  '384' ],
        },
        "BMW-512" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::BMW',  '512' ],
        },
        "CRC-8" => {
            'handler'   => \&digest_crc_interface_handler,
            'arguments' => [ 'Digest::CRC', 'crc8' ],
        },
        "CRC-16" => {
            'handler'   => \&digest_crc_interface_handler,
            'arguments' => [ 'Digest::CRC', 'crc16' ],
        },
        "CRC-32" => {
            'handler'   => \&digest_crc_interface_handler,
            'arguments' => [ 'Digest::CRC', 'crc32' ],
        },
        "CRC-64" => {
            'handler'   => \&digest_crc_interface_handler,
            'arguments' => [ 'Digest::CRC', 'crc64' ],
        },
        "CRC-CCITT" => {
            'handler'   => \&digest_crc_interface_handler,
            'arguments' => [ 'Digest::CRC', 'crcccitt' ],
        },
        "CRC-OpenPGP-Armor" => {
            'handler'   => \&digest_crc_interface_handler,
            'arguments' => [ 'Digest::CRC', 'crcopenpgparmor' ],
        },
        "ECHO-224" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::ECHO',  '224' ],
        },
        "ECHO-256" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::ECHO',  '256' ],
        },
        "ECHO-384" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::ECHO',  '384' ],
        },
        "ECHO-512" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::ECHO',  '512' ],
        },
        "ED2K" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::ED2K' ],
        },
        "EdonR-224" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::EdonR',  '224' ],
        },
        "EdonR-256" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::EdonR',  '256' ],
        },
        "EdonR-384" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::EdonR',  '384' ],
        },
        "EdonR-512" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::EdonR',  '512' ],
        },
        "Fugue-224" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Fugue',  '224' ],
        },
        "Fugue-256" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Fugue',  '256' ],
        },
        "Fugue-384" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Fugue',  '384' ],
        },
        "Fugue-512" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Fugue',  '512' ],
        },
        "GOST" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::GOST' ],
        },
        "Groestl-224" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Groestl',  '224' ],
        },
        "Groestl-256" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Groestl',  '256' ],
        },
        "Groestl-384" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Groestl',  '384' ],
        },
        "Groestl-512" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Groestl',  '512' ],
        },
        "Hamsi-224" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Hamsi',  '224' ],
        },
        "Hamsi-256" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Hamsi',  '256' ],
        },
        "Hamsi-384" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Hamsi',  '384' ],
        },
        "Hamsi-512" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Hamsi',  '512' ],
        },
        "JH-224" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::JH',  '224' ],
        },
        "JH-256" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::JH',  '256' ],
        },
        "JH-384" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::JH',  '384' ],
        },
        "JH-512" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::JH',  '512' ],
        },
        "Keccak-224" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Keccak',  '224' ],
        },
        "Keccak-256" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Keccak',  '256' ],
        },
        "Keccak-384" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Keccak',  '384' ],
        },
        "Keccak-512" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Keccak',  '512' ],
        },
        "Luffa-224" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Luffa',  '224' ],
        },
        "Luffa-256" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Luffa',  '256' ],
        },
        "Luffa-384" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Luffa',  '384' ],
        },
        "Luffa-512" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Luffa',  '512' ],
        },
        "MD2" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::MD2' ],
        },
        "MD4" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::MD4' ],
        },
        "MD5" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::MD5' ],
        },
        "SHA-1" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::SHA',  '1' ],
        },
        "SHA-224" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::SHA',  '224' ],
        },
        "SHA-256" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::SHA',  '256' ],
        },
        "SHA-384" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::SHA',  '384' ],
        },
        "SHA-512" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::SHA',  '512' ],
        },
        "SHA3-224" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::SHA3',  '224' ],
        },
        "SHA3-256" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::SHA3',  '256' ],
        },
        "SHA3-384" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::SHA3',  '384' ],
        },
        "SHA3-512" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::SHA3',  '512' ],
        },
        "SHA3-SHAKE128" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::SHA3',  '128000' ],
        },
        "SHA3-SHAKE256" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::SHA3',  '256000' ],
        },
        "SHAvite3-224" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::SHAvite3',  '224' ],
        },
        "SHAvite3-256" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::SHAvite3',  '256' ],
        },
        "SHAvite3-384" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::SHAvite3',  '384' ],
        },
        "SHAvite3-512" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::SHAvite3',  '512' ],
        },
        "SIMD-224" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::SIMD',  '224' ],
        },
        "SIMD-256" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::SIMD',  '256' ],
        },
        "SIMD-384" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::SIMD',  '384' ],
        },
        "SIMD-512" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::SIMD',  '512' ],
        },
        "Shabal-224" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Shabal',  '224' ],
        },
        "Shabal-256" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Shabal',  '256' ],
        },
        "Shabal-384" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Shabal',  '384' ],
        },
        "Shabal-512" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Shabal',  '512' ],
        },
        "Skein-256" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Skein',  '256' ],
        },
        "Skein-512" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Skein',  '512' ],
        },
        "Skein-1024" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Skein',  '1024' ],
        },
        "Whirlpool" => {
            'handler'   => \&digest_interface_handler,
            'arguments' => [ 'Digest::Whirlpool' ],
        },
    } },
};



# Constructor arguments hook validates parameters.
sub BUILDARGS {

    my $class = shift @_;
    my $context = shift @_;

    # If not context (i.e. FSTreeIntegrityWatch base class instance) is provided
    # by the caller, create an instance with default parameters.
    if (not defined($context)) {
        $context = FSTreeIntegrityWatch->new();
    }

    return { 'context' => $context };

}

# Compute checksum on all files using all algorithms in the instance's context.
# returns
#   checksums hash ref of the instance's context
# throws
#   FSTreeIntegrityWatch::Exception::Digest in case of any error
sub compute_checksums {

    my $self = shift @_;

    my $cs = $self->context->checksums();

    foreach my $filename (@{$self->context->files()}) {
        foreach my $alg (@{$self->context->algorithms()}) {

            my $err = undef;
            if (not defined($filename)) {
                $err = "No filename specified.";
            } elsif (-e $filename and -f $filename and -r $filename) {
                $err = "No digest algorithm specified." if (not defined($alg));
            } elsif (-d $filename) {
                $self->context->print_warning("'$filename' is a directory, computing its checksum is meaningless");
                next;
            } else {
                $self->context->print_warning("'$filename' is not a readable file; skipping.");
                next;
            }
            $self->context->exp('Digest', $err) if (defined($err));

            $self->context->print_info("computing '$alg' checksum on '$filename'");

            my $checksum = undef;
            try {
                if (exists($self->algorithms->{$alg})) {
                    my $handler = $self->algorithms->{$alg}->{'handler'};
                    my @args = @{$self->algorithms->{$alg}->{'arguments'}};
                    $checksum = &$handler($self, $filename, @args);
                } else {
                    $self->context->exp('Digest', "Unknown algorithm '$alg'.");
                }
            } catch {
                $self->context->exp('Digest', "Digest computation using '$alg' algorithm failed.\n".decode_locale_if_necessary($_));
            };

            $cs->{$filename}->{$alg}->{'checksum_value'} = $checksum;
            $cs->{$filename}->{$alg}->{'computed_at'} = time;

        }
    }

    return $cs;

}

# Compute checksum on given file using given module. The module is loaded
# dynamically using Module::Load. It is assumed the module implements Digest
# module interace, i.e. methods:
#   new() or new($alg_ver) respectively
#   addfile($fh)
#   hexdigest
# args
#   name of file to compute the digest of
#   name of module with hash algorithm implementation
#   optional: identifier of particular algorithm version
# returns
#   checksum as string or
#   undef in case of any error
# throws
#   FSTreeIntegrityWatch::Exception::Digest in case of any error
sub digest_interface_handler {

    my $self = shift @_;
    my $filename = shift @_;
    my $module_name = shift @_;
    my $alg_ver = shift @_;

    my $err = undef;
    if (not defined($filename)) {
        $err = "No filename specified.";
    } elsif (-e $filename and -f $filename and -r $filename) {
        $err = "No digest module specified." if (not defined($module_name));
        $err = "No valid digest version specified." if (defined($alg_ver) and $alg_ver =~ /^\s*$/);
    } else {
        $err = "'$filename' is not a readable file.";
    }
    $self->context->exp('Digest', $err) if (defined($err));

    my ($checksumer, $checksum);
    try {
        load $module_name;
        if (defined($alg_ver)) {
            $checksumer = "$module_name"->new($alg_ver);
        } else {
            $checksumer = "$module_name"->new();
        }
        open (my $fh, '<', $filename)
            or $self->context->exp('Digest', "Can't open '$filename': ".decode_locale_if_necessary($!));
        binmode ($fh);
        $checksum = $checksumer->addfile($fh)->hexdigest;
        close($fh)
            or $self->context->exp('Digest', "Can't close '$filename': ".decode_locale_if_necessary($!));
    } catch {
        $self->context->exp('Digest', "Digest computation using '$module_name' module failed.\n".decode_locale_if_necessary($_));
    };

    return $checksum;

}

# Compute checksum on given file using given module. The module is loaded
# dynamically using Module::Load. It is assumed the module implements
# Digest::CRC module interace, i.e. methods:
#   new(type => $alg_ver)
#   addfile($fh)
#   hexdigest
# args
#   name of file to compute the digest of
#   name of module with hash algorithm implementation
#   identifier of particular algorithm version
# returns
#   checksum as string or
#   undef in case of any error
# throws
#   FSTreeIntegrityWatch::Exception::Digest in case of any error
sub digest_crc_interface_handler {

    my $self = shift @_;
    my $filename = shift @_;
    my $module_name = shift @_;
    my $alg_ver = shift @_;

    my $err = undef;
    if (not defined($filename)) {
        $err = "No filename specified.";
    } elsif (-e $filename and -f $filename and -r $filename) {
        $err = "No digest module specified." if (not defined($module_name));
        $err = "No valid digest version specified." unless (defined($alg_ver) and $alg_ver !~ /^\s*$/);
    } else {
        $err = "'$filename' is not a readable file.";
    }
    $self->context->exp('Digest', $err) if (defined($err));

    my ($checksumer, $checksum);
    try {
        load $module_name;
        $checksumer = "$module_name"->new('type' => $alg_ver);
        open (my $fh, '<', $filename)
            or $self->context->exp('Digest', "Can't open '$filename': ".decode_locale_if_necessary($!));
        binmode ($fh);
        $checksum = $checksumer->addfile($fh)->hexdigest;
        close($fh)
            or $self->context->exp('Digest', "Can't close '$filename': ".decode_locale_if_necessary($!));
    } catch {
        $self->context->exp('Digest', "Digest computation using '$module_name' module failed.\n".decode_locale_if_necessary($_));
    };

    return $checksum;

}


1;


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
