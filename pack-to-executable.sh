#!/bin/bash

export ifile='fstree-integrity-watch.pl'
export PP_OPTS="--verbose=3 --compile --execute --clean --compress 9 -I lib -M FSTreeIntegrityWatch::Packer"


# Stand-alone setup
export ofile='fstree-integrity-watch.packed-standalone'
echo "### Building"
echo "###   ${ofile}"
echo "### for use independently of Perl installation"
pp       -o "${ofile}" "${ifile}"

# For use with Perl interpreter only, without core modules
export ofile='fstree-integrity-watch.packed-for-perl-interpreter-only-without-core-modules.pl'
echo "### Building"
echo "###   ${ofile}"
echo "### for use with Perl interpreter without core modules installed"
pp -B -P -o "${ofile}" "${ifile}"

# For use with Perl with core module installed
export ofile='fstree-integrity-watch.packed-for-perl-interpreter-with-core-modules.pl'
echo "### Building"
echo "###   ${ofile}"
echo "### for use with Perl with core module installed"
pp    -P -o "${ofile}" "${ifile}"

# For use with Perl with PAR.pm and its dependencies installed
export ofile='fstree-integrity-watch.packed-for-perl-interpreter-with-PAR.pm-and-its-dependencies.pl'
echo "### Building"
echo "###   ${ofile}"
echo "###   ${ofile%.pl}.par"
echo "### for use with Perl with PAR.pm and its dependencies installed"
pp       -o "${ofile%.pl}.par" -p "${ifile}"
head -n 1 "${ifile}" > "${ofile}"
echo "use PAR '${ofile%.pl}.par';" >> "${ofile}"
tac "${ifile}" | head -n -1 | tac >> "${ofile}"
chmod u+x "${ofile}"
