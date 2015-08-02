
package FSTreeIntegrityWatch::Digest;

use strict;
use warnings;
use utf8;


# Package modules
use FSTreeIntegrityWatch::Tools qw(decode_locale_if_necessary);

# External modules
use Digest;
use Try::Tiny;


# Use Class::Tiny for class construction.
use Class::Tiny 1.001 qw(context); # BUILDARGS method was introduced in version 1.001 of the module.



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
            } else {
                $err = "'$filename' is not a readable file.";
            }

            $self->context->exp('Digest', $err) if (defined($err));
            my ($checksumer, $checksum);
            try {
                $checksumer = Digest->new("$alg", 'b');
                $checksum = $checksumer->addfile($filename)->hexdigest;
            } catch {
                $self->context->exp('Digest', "Digest computation using '$alg' algorithm failed.\n".decode_locale_if_necessary($_));
            };

            $cs->{$filename}->{$alg}->{'checksum_value'} = $checksum;
            $cs->{$filename}->{$alg}->{'checksum_time'} = time;

        }
    }

    return $cs;

}


1;


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
