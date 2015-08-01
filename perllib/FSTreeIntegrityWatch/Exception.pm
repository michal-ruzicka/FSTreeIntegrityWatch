
package FSTreeIntegrityWatch::Exception;

# Great tutorial: http://www.drdobbs.com/web-development/exception-handling-in-perl-with-exceptio/184416129

use strict;
use warnings;
use utf8;

# Public methods
use Exporter 'import';
our @EXPORT_OK = qw(
    general_error
    config_error
    digest_error
);
our %EXPORT_TAGS = (
    all => [ @EXPORT_OK ],
);

# Declare hierarchy of exceptions.
use Exception::Class (

    'FSTreeIntegrityWatch::Exception' => {
        'alias'       => 'general_error',
        'description' => 'generic base class for all FSTreeIntegrityWatch exceptions',
    },

    'FSTreeIntegrityWatch::Exception::Configuration' => {
        'alias'       => 'config_error',
        'isa'         => 'FSTreeIntegrityWatch::Exception',
        'description' => 'improper FSTreeIntegrityWatch module configuration',
    },

    'FSTreeIntegrityWatch::Exception::Digest' => {
        'alias'       => 'digest_error',
        'isa'         => 'FSTreeIntegrityWatch::Exception',
        'description' => 'error thrown during hash computation',
    },

);


1;


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en