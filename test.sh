#!/bin/bash

locale='cs_CZ.utf8'
export LC_ALL="$locale"
export LANG="$locale"
locale
echo 'Žluťoučký šíleně kůň.' | ./locale-test.pl 'Kůň: Šílený žluťoučký – test.'

echo

locale='en_GB.iso885915'
export LC_ALL="$locale"
export LANG="$locale"
locale
echo 'Žluťoučký šíleně kůň.' | ./locale-test.pl 'Kůň: Šílený žluťoučký – test.'
