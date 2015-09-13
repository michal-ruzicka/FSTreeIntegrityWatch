
package FSTreeIntegrityWatch::BagIt;

use strict;
use warnings;
use utf8;


# Package modules
use FSTreeIntegrityWatch::Tools qw(decode_locale_if_necessary);

# External modules
use IPC::Open3;


# Use Class::Tiny for class construction.
use Class::Tiny 1.001 qw(context), { # BUILDARGS method was introduced in version 1.001 of the module.
    'bagit_py' => 'bagit.py',
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
    my $r = { 'context' => $context };
       $r->{'bagit_py'} = $context->bagit_py() if (defined($context->bagit_py()));

    return $r;

}

# Validates all files in files array ref of the instance's context to be
# directories in BagIt format and if so to be valid BagIt directories.
# returns
#   validated_bagits hash ref of the instance's context
# throws
#   FSTreeIntegrityWatch::Exception::BagIt in case of any error
sub validate {

    my $self = shift @_;

    my $vb = $self->context->validated_bagits();

    foreach my $filename (@{$self->context->files()}) {

        my $err = undef;
        if (not defined($filename)) {
            $err = "No filename specified.";
        } elsif (not -d $filename) {
            #$self->context->print_info("'$filename' is not a directory, verifying it to be BagIt directory is meaningless");
            next;
        } elsif (not -f File::Spec->catfile($filename, 'bagit.txt')) {
            #$self->context->print_info("'".File::Spec->catfile($filename, 'bagit.txt')."' does not exist, skipping '$filename' as not seeming to be a BagIt directory");
            next;
        }
        $self->context->exp('BagIt', $err) if (defined($err));

        $self->context->print_info("validating '$filename' to be a valid BagIt directory");
        my ($is_valid, $description, $return_value) = $self->validate_dir($filename);
        $vb->{$filename} = {
            'is_valid'     => $is_valid,
            'description'  => decode_locale_if_necessary($description),
            'return_value' => $return_value,
        };

    }

    return $vb;

}

# Validates given path to be a directory in the valid BagIt format.
# args
#   directory path to be validated as a BagIt dir
# returns
#   tuple (is_valid boolean flag,
#          result summary description string,
#          validation tool return value)
sub validate_dir {

    my $self = shift @_;
    my $bagit_dir = shift @_;

    my ($bagit_py_rv, $bagit_py_out, $bagit_py_err, $bagit_py_sum_msg);
    my $pid = open3(\*BAGIT_PY_IN, \*BAGIT_PY_OUT, \*BAGIT_PY_ERR,
                    $self->bagit_py, '--validate', $bagit_dir);
    close(BAGIT_PY_IN);
    $bagit_py_out .= $_ while(<BAGIT_PY_OUT>);
    while(<BAGIT_PY_ERR>) {
        $bagit_py_err .= $_;
        $bagit_py_sum_msg = $_;
    }
    waitpid($pid, 0);
    $bagit_py_rv = $? >> 8;

    chomp $bagit_py_sum_msg;
    $bagit_py_sum_msg =~ s/^.*? is ((in)?valid(:|$).*)$/$1/g;

    return (($bagit_py_rv == 0 ? 1 : 0), $bagit_py_sum_msg, $bagit_py_rv);

}


1;


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
