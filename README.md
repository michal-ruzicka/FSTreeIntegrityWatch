FSTreeIntegrityWatch – Implementation in C language
===================================================

Filesystem Tree Extended Attributes File Integrity Tool
-------------------------------------------------------

A tool to store/check file integrity information in filesystem extended
attributes.

See
 * http://man7.org/linux/man-pages/man5/attr.5.html
 * http://man7.org/linux/man-pages/man1/getfattr.1.html
 * http://man7.org/linux/man-pages/man1/setfattr.1.html


## Usage

The tools has build-in help. To see usage information run

`extattr-file-integrity -h`


## Dependencies

 * GLib >= 2.0
 * GnuTLS >= 2.10.0
 * libattr


## Compilation

`gcc -Wall -g -O3 $(pkg-config --cflags --libs glib-2.0) $(pkg-config --cflags --libs gnutls) -o extattr-file-integrity extattr-file-integrity.c`



<!--
  vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
-->
