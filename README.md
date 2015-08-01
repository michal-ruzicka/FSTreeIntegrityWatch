FSTreeIntegrityWatch
====================

Filesystem Extended Attributes File Integrity Tool
--------------------------------------------------

Tool to store/check file integrity information in filesystem extended
attributes.

See 
 * http://man7.org/linux/man-pages/man5/attr.5.html


### extattr-file-integrity.pl

The Perl script uses `File::ExtAttr` module that depends on `libattr`.

In case of `cpan File::ExtAttr` installation error your system possibly needs 
`libattr-devel` packages to be installed.

See
 * http://search.cpan.org/~richdawe/File-ExtAttr/lib/File/ExtAttr.pm



<!--
  vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
-->
